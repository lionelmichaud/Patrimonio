//
//  Financial.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import AppFoundation
import Statistics
import FiscalModel
import EconomyModel
import NamedValue
import Ownership
import Persistence

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.FreeInvestement")

public enum FreeInvestementError: Error {
    case IlegalOperation
}

public typealias FreeInvestmentArray = ArrayOfNameableValuable<FreeInvestement>

// MARK: - Placement à versement et retrait variable et à taux fixe

/// Placement à versement et retrait libres et à taux fixe
/// Les intérêts sont capitalisés lors de l'appel à capitalize()
// conformité à JsonCodableToBundleP nécessaire pour les TU; sinon Codable suffit
public struct FreeInvestement: Identifiable, JsonCodableToBundleP, FinancialEnvelopP, QuotableP {
    
    // MARK: - Nested Types
    
    /// Situation annuelle de l'investissement
    public struct State: Codable, Equatable {
        public var year       : Int = 0
        public var interest   : Double = 0 // portion of interests included in the Value
        public var investment : Double = 0 // portion of investment included in the Value
        public var value      : Double { interest + investment } // valeur totale
    }
    
    enum CodingKeys: CodingKey {
        case name
        case note
        case website
        case ownership
        case type
        case interestRateType
        case lastKnownState
    }

    // MARK: - Static Properties
    
    static var defaultFileName : String = "FreeInvestement.json"
    
    private static var simulationMode: SimulationModeEnum = .deterministic
    // dependencies
    private static var economyModel : EconomyModelProviderP!
    public static var fiscalModel   : Fiscal.Model!
    
    // tous ces actifs sont dépréciés de l'inflation
    private static var inflation: Double { // %
        FreeInvestement.economyModel.inflation(withMode: simulationMode)
    }
    
    /// averageSecuredRate: taux à long terme - rendement des obligations - en moyenne
    /// averageStockRate: rendement des actions - en moyenne
    private static var rates: (averageSecuredRate: Double, averageStockRate: Double) { // %
        let rates = FreeInvestement.economyModel.rates(withMode: simulationMode)
        return (rates.securedRate, rates.stockRate)
    }
    
    // MARK: - Static Methods
    
    /// Dependency Injection: Setter Injection
    public static func setEconomyModelProvider(_ economyModel : EconomyModelProviderP) {
        FreeInvestement.economyModel = economyModel
    }
    
    /// Dependency Injection: Setter Injection
    public static func setFiscalModelProvider(_ fiscalModel : Fiscal.Model) {
        FreeInvestement.fiscalModel = fiscalModel
    }
    
    public static func setSimulationMode(to thisMode: SimulationModeEnum) {
        FreeInvestement.simulationMode = thisMode
    }
    
    private static func rates(in year : Int)
    -> (securedRate : Double,
        stockRate   : Double) {
        FreeInvestement.economyModel.rates(in                 : year,
                                           withMode           : simulationMode,
                                           simulateVolatility : Preferences.standard.simulateVolatility)
    }
    
    // MARK: - Properties
    
    public var id = UUID()
    public var name    : String
    public var note    : String
    /// Site web de l'établissement qui détient le bien
    public var website : URL?
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    /// Droits de propriété sur le bien
    public var ownership       : Ownership = Ownership()
    /// Niveau de risque sur la valorisation du bien
    public var riskLevel       : RiskLevel? {
        switch interestRateType {
            case .contractualRate:
                // taux contractuel fixe
                return .veryLow

            case .marketRate(let stockRatio):
                // taux de marché variable
                return riskScale?.rating(stockRatio)
        }
    }
    /// Niveau de liquidité du bien
    public var liquidityLevel  : LiquidityLevel? {
        switch type {
            case .lifeInsurance:
                return .medium

            case .pea:
                return .medium

            case .other:
                return .high
        }
    }
    /// Type de l'investissement
    public var type            : InvestementKind
    /// Type de taux de rendement
    public var interestRateType: InterestRateKind
    /// Dernière constitution du capital connue (relevé bancaire)
    public var lastKnownState  : State {
        didSet {
            resetCurrentState()
        }
    }
    /// Constitution du capital à l'instant présent
    var currentState           : State = State()
    /// Intérêts cumulés au cours du temps depuis la transmission de l'usufruit jusqu'à l'instant présent
    var currentStateAfterTransmission: State?
    /// Le bien est-il ouvert aux placements: un bien est fermé à l'investissement lorsque son unique propriétaire est décédé
    var isOpen: Bool = true
    
    // MARK: - Computed Properties
    
    /// Rendement en % avant charges sociales si prélevées à la source annuellement [0, 100%]
    public var averageInterestRate: Double {
        switch interestRateType {
            case .contractualRate(let fixedRate):
                // taux contractuel fixe
                return fixedRate
                
            case .marketRate(let stockRatio):
                // taux de marché variable
                let stock = stockRatio / 100.0
                // taux d'intérêt composite fonction de la composition du portefeuille
                let rate =
                    stock * FreeInvestement.rates.averageStockRate
                    + (1.0 - stock) * FreeInvestement.rates.averageSecuredRate
                return rate
        }
    }
    /// Rendement en % avant charges sociales si prélevées à la source annuellement [0, 100%] et net d'inflation
    public var averageInterestRateNetOfInflation: Double {
        averageInterestRate - FreeInvestement.inflation
    }
   /// Rendement en % après charges sociales si prélevées à la source annuellement [0, 100%] et net d'inflation
    public var averageInterestRateNetOfTaxesAndInflation: Double {
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ?
                            FreeInvestement.fiscalModel.financialRevenuTaxes.net(averageInterestRateNetOfInflation) :
                            averageInterestRateNetOfInflation)
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return averageInterestRateNetOfInflation
        }
    }
    /// Rendement en % après charges sociales si prélevées à la source annuellement [0, 100%]
    public var averageInterestRateNetOfTaxes: Double { // % fixe après charges sociales si prélevées à la source annuellement
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ?
                            FreeInvestement.fiscalModel.financialRevenuTaxes.net(averageInterestRate) :
                            averageInterestRate)
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return averageInterestRate
        }
    }
    /// Intérêts cumulés au cours du temps depuis la transmission de l'usufruit jusqu'à l'instant présent
    var cumulatedInterestsSinceSuccession: Double? {
        currentStateAfterTransmission?.interest
    }
    /// Intérêts cumulés au cours du temps depuis l'origine jusqu'à l'instant présent
    private var cumulatedInterests: Double {
        currentState.interest
    }

    // MARK: - Initialization
    
    public init(year             : Int,
                name             : String,
                note             : String,
                type             : InvestementKind,
                interestRateType : InterestRateKind,
                initialValue     : Double = 0.0,
                initialInterest  : Double = 0.0) {
        self.name             = name
        self.note             = note
        self.type             = type
        self.interestRateType = interestRateType
        self.lastKnownState = State(year       : year,
                                    interest   : initialInterest,
                                    investment : initialValue - initialInterest)
        self.currentState   = self.lastKnownState
    }
    
    // MARK: - Methods
    
    /// Taux d'intérêt annuel en %
    /// net de charges sociales si prélevées à la source annuellement
    /// net d'inflation annuelle
    /// - Parameter idx: [0, nb d'années simulées - 1]
    /// - Returns: Taux d'intérêt annuel en % [0, 100%] net d'inflation annuelle et net de charges sociales si prélevées à la source annuellement
    private func interestRate(in year: Int) -> Double {
        switch interestRateType {
            case .contractualRate(let fixedRate):
                // taux contractuel fixe
                return fixedRate
                
            case .marketRate(let stockRatio):
                // taux de marché variable
                let stock = stockRatio / 100.0
                let rates = FreeInvestement.rates(in: year)
                // taux d'intérêt composite fonction de la composition du portefeuille
                let rate = stock * rates.stockRate + (1.0 - stock) * rates.securedRate
                return rate
        }
    }
    
    private func interestRateNetOfInflation(in year: Int) -> Double {
        interestRate(in: year) - FreeInvestement.inflation
    }

    private func interestRateNetOfTaxesAndInflation(in year: Int) -> Double {
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ?
                            FreeInvestement.fiscalModel.financialRevenuTaxes.net(interestRateNetOfInflation(in: year)) :
                            interestRateNetOfInflation(in: year))
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return interestRateNetOfInflation(in: year)
        }
    }
    
    /// Intérêts annuels en € du capital accumulé à l'instant présent
    /// net de charges sociales si prélevées à la source annuellement
    /// net d'inflation annuelle
    /// - Parameter idx: [0, nb d'années simulées - 1]
    /// - Returns: Intérêts annuels en € net d'inflation annuelle et net de charges sociales si prélevées à la source annuellement
    private func yearlyInterestNetOfTaxesAndInflation(in year: Int) -> Double {
        currentState.value * interestRateNetOfTaxesAndInflation(in: year) / 100.0
    }
    
    /// Fractionnement d'un retrait entre: versements cumulés et intérêts cumulés
    /// - Parameter amount: montant du retrait
    func split(removal amount: Double) -> (investment: Double, interest: Double) {
        let deltaInterest   = amount * (currentState.interest / currentState.value)
        let deltaInvestment = amount - deltaInterest
        return (deltaInvestment, deltaInterest)
    }
    
    /// Retourne la valeur estimée en fin d'année `year` = somme des versements + somme des intérêts
    public func value(atEndOf year: Int) -> Double {
        if year == self.currentState.year {
            // valeur de la dernière année simulée
            return currentState.value
            
        } else if year == self.lastKnownState.year - 1 {
            return lastKnownState.value
            
        } else {
            // extrapoler la valeur à partir de la situation initiale avec un taux constant moyen
            return try! futurValue(payement     : 0,
                                   interestRate : averageInterestRateNetOfTaxesAndInflation/100,
                                   nbPeriod     : year - lastKnownState.year,
                                   initialValue : lastKnownState.value)
        }
    }

    /// True si le bien est déjà ouvert en fin d'année `year`.
    /// Cad si `lastKnownState.year` <= `year`
    /// - Parameter year: Année
    public func isOpen(in year: Int) -> Bool {
        (lastKnownState.year...).contains(year) && isOpen
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    /// - Warning: les assurance vie ne sont pas inclues car hors succession
    public func ownedValue(by ownerName      : String,
                           atEndOf year      : Int,
                           evaluationContext : EvaluationContext) -> Double {
        var evaluatedValue : Double

        // cas particuliers des décotes sur la valeur du bien
        switch evaluationContext {
            case .legalSuccession:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // les assurance vie ne sont pas inclues car hors succession légale
                        return 0
                        
                    default:
                        // le défunt est-il usufruitier seulement usufruitier ?
                        if ownership.isDismembered &&
                            ownership.hasAnUsufructOwner(named: ownerName) &&
                            !ownership.hasABareOwner(named: ownerName) {
                            // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                            // l'usufruit n'est donc pas intégré à la masse successorale du défunt
                            return 0
                        }
                        // prendre la valeur totale du bien sans aucune décote
                        evaluatedValue = value(atEndOf: year)
                }
                
            case .lifeInsuranceSuccession, .lifeInsuranceTransmission:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // prendre la valeur totale du bien sans aucune décote
                        evaluatedValue = value(atEndOf: year)

                    default:
                        // on recherche uniquement les assurances vies
                        return 0
                }
                
            case .ifi, .isf, .patrimoine:
                // prendre la valeur totale du bien sans aucune décote
                evaluatedValue = value(atEndOf: year)
        }
        
        // calculer la part de propriété
        let value = evaluatedValue == 0 ? 0 : ownership.ownedValue(by                : ownerName,
                                                                   ofValue           : evaluatedValue,
                                                                   atEndOf           : year,
                                                                   evaluationContext : evaluationContext)
        return value
    }
    
    /// Réaliser un dépôt
    /// - Parameter amount: Montant du dépôt
    /// - Note: Les intérêts sur le dépôt seront comptabilisés dès que `capitalize()` sera appelée.
    public mutating func deposit(_ amount: Double) {
        currentState.investment += amount
    }
    
    /// Capitaliser les intérêts de l'année `year`: à faire une fois par an et apparaissent dans l'année `year`.
    /// - Note: Si la volatilité est prise en compte dans le modèle économique alors le taux change chaque année
    public mutating func capitalize(atEndOf year: Int) throws {
        guard (currentState.year ... (currentState.year + 1)).contains(year) else {
            customLog.log(level: .error,
                          "FreeInvestementError.capitalize: capitalisation sur un nombre d'année différent de 0 et 1")
            throw FreeInvestementError.IlegalOperation
        }
        
        if year == currentState.year + 1 {
            let interests = yearlyInterestNetOfTaxesAndInflation(in: year)
            
            currentState.interest += interests
            currentState.year = year
            
            currentStateAfterTransmission?.interest += interests
        }
    }
    
    /// Remettre la valeur courante à la date de fin d'année passée
    public mutating func resetCurrentState() {
        currentStateAfterTransmission = nil
        isOpen = true
        
        // calculer la valeur de currentState à la date de fin d'année passée
        let estimationYear = CalendarCst.thisYear - 1
        
        if estimationYear == lastKnownState.year {
            currentState = lastKnownState
            
        } else if estimationYear == lastKnownState.year - 1 {
            // pour gérer le cas où on met à jour les données à la fin de l'année en cours
            currentState = lastKnownState
            let lastKnownStateYear = lastKnownState.year
            customLog.log(level: .error,
                          "estimationYear (\(estimationYear, privacy: .public)) < initialState.year (\(lastKnownStateYear))")
            
        } else {
            // extrapoler la valeure à partir de la situation initiale
            do {
                let futurVal = try futurValue(payement     : 0,
                                              interestRate : averageInterestRateNetOfTaxesAndInflation/100,
                                              nbPeriod     : estimationYear - lastKnownState.year,
                                              initialValue : lastKnownState.value)
                currentState = State(year       : estimationYear,
                                     interest   : lastKnownState.interest + (futurVal - lastKnownState.value),
                                     investment : lastKnownState.investment)
            } catch FinancialMathError.negativeNbPeriod {
                // on ne remonte pas le temps
                let lastKnownStateYear = lastKnownState.year
                customLog.log(level: .fault,
                              "estimationYear (\(estimationYear, privacy: .public)) < initialState.year (\(lastKnownStateYear))")
                fatalError("estimationYear (\(estimationYear)) < initialState.year (\(lastKnownState.year))")
            } catch {
                customLog.log(level: .fault, "FinancialMathError.futurValue")
                fatalError("FinancialMathError.futurValue")
            }
        }
    }
    
    public mutating func initializeCurrentInterestsAfterTransmission(yearOfTransmission: Int) {
        currentStateAfterTransmission =
            State(year       : yearOfTransmission,
                  interest   : 0,
                  investment : 0)
    }
}

// MARK: - Extensions

extension FreeInvestement: Comparable {
    public static func < (lhs: FreeInvestement, rhs: FreeInvestement) -> Bool {
        return (lhs.name < rhs.name)
    }
}

extension FreeInvestement: CustomStringConvertible {
    public var description: String {
        """

        INVESTISSEMENT LIBRE: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Quotation:
          - Risque:    \(riskLevel?.description ?? "indéfini")
          - Liquidité: \(liquidityLevel?.description ?? "indéfini")
        - Type:\(type.description.withPrefixedSplittedLines("  "))
        - Ouvert à l'investissement: \(isOpen)
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
        - Valeur (\(CalendarCst.thisYear)): \(value(atEndOf: CalendarCst.thisYear).€String)
        - Etat initial: (year: \(lastKnownState.year), interest: \(lastKnownState.interest.€String), invest: \(lastKnownState.investment.€String), Value: \(lastKnownState.value.€String))
        - Etat courant: (year: \(currentState.year), interest: \(currentState.interest.€String), invest: \(currentState.investment.€String), Value: \(currentState.value.€String))
        - Intérêt Cumulés depuis la transmission: (year: \(currentStateAfterTransmission?.year ?? 0), interest: \(currentStateAfterTransmission?.interest.€String ?? 0.€String))
        - \(interestRateType)
        - Taux d'intérêt net d'inflation avant prélèvements sociaux:   \(averageInterestRateNetOfInflation) %
        - Taux d'intérêt net d'inflation, net de prélèvements sociaux: \(averageInterestRateNetOfTaxesAndInflation) %
        """
    }
}
