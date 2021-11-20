//
//  PeriodicInvestment.swift
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
import Persistence
import Ownership

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.PeriodicInvestement")

public enum PeriodicInvestementError: Error {
    case IlegalOperation
}

public typealias PeriodicInvestementArray = ArrayOfNameableValuable<PeriodicInvestement>

// MARK: - Placement à versements périodiques, fixes, annuels et à taux fixe

/// Placement à versements périodiques, fixes, annuels et à taux fixe
/// Tous les intérêts sont capitalisés
// conformité à JsonCodableToBundleP nécessaire pour les TU; sinon Codable suffit
public struct PeriodicInvestement: Identifiable, JsonCodableToBundleP, FinancialEnvelopP {
    
    // MARK: - Nested Types
    
    /// Situation annuelle de l'investissement
    public struct State: Codable, Equatable {
        public var firstYear         : Int
        public var initialInterest   : Double // portion of interests included in the Value
        public var initialInvestment : Double // portion of investment included in the Value
        public var initialValue      : Double { initialInterest + initialInvestment } // valeur totale
    }
    
    // MARK: - Static Properties
    
    static var defaultFileName: String = "PeriodicInvestement.json"
    
    private static var simulationMode: SimulationModeEnum = .deterministic
    // dependencies
    private static var economyModel : EconomyModelProviderP!
    private static var fiscalModel  : Fiscal.Model!
    
    // tous ces revenus sont dépréciés de l'inflation
    private static var inflation: Double { // %
        PeriodicInvestement.economyModel.inflation(withMode: simulationMode)
    }
    
    /// taux à long terme - rendem
    /// rendement des actions - en moyenne
    private static var rates: (averageSecuredRate: Double, averageStockRate: Double) { // %
        let rates = PeriodicInvestement.economyModel.rates(withMode: simulationMode)
        return (rates.securedRate, rates.stockRate)
    }
    
    // MARK: - Static Methods
    
    /// Dependency Injection: Setter Injection
    public static func setEconomyModelProvider(_ economyModel : EconomyModelProviderP) {
        PeriodicInvestement.economyModel = economyModel
    }
    
    /// Dependency Injection: Setter Injection
    public static func setFiscalModelProvider(_ fiscalModel : Fiscal.Model) {
        PeriodicInvestement.fiscalModel = fiscalModel
    }
    
    public static func setSimulationMode(to thisMode: SimulationModeEnum) {
        PeriodicInvestement.simulationMode = thisMode
    }
    
    private static func rates(in year : Int)
    -> (securedRate : Double,
        stockRate   : Double) {
        PeriodicInvestement.economyModel.rates(in                 : year,
                                               withMode           : simulationMode,
                                               simulateVolatility : UserSettings.shared.simulateVolatility)
    }
    
    // MARK: - Properties
    
    public var id              = UUID()
    public var name            : String
    public var note            : String = ""
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    public var ownership       : Ownership = Ownership()
    public var type            : InvestementKind
    public var yearlyPayement  : Double = 0.0 // versements nets de frais
    public var yearlyCost      : Double = 0.0 // Frais sur versements
    // date d'ouverture
    public var firstYear       : Int // au 31 décembre
    public var initialValue    : Double = 0.0
    public var initialInterest : Double = 0.0 // portion of interests included in the initialValue
    // date de liquidation
    public var lastYear        : Int // au 31 décembre
    // rendement
    public var interestRateType       : InterestRateKind // type de taux de rendement
    public var averageInterestRate    : Double {// % avant charges sociales si prélevées à la source annuellement
        switch interestRateType {
            case .contractualRate( let fixedRate):
                // taux contractuel fixe
                return fixedRate - PeriodicInvestement.inflation
                
            case .marketRate(let stockRatio):
                // taux de marché variable
                let stock = stockRatio / 100.0
                // taux d'intérêt composite fonction de la composition du portefeuille
                let rate = stock * PeriodicInvestement.rates.averageStockRate + (1.0 - stock) * PeriodicInvestement.rates.averageSecuredRate
                return rate - PeriodicInvestement.inflation
        }
    }
    public var averageInterestRateNet : Double { // % fixe après charges sociales si prélevées à la source annuellement
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // si assurance vie: le taux net est le taux brut - charges sociales si celles-ci sont prélèvées à la source anuellement
                return (periodicSocialTaxes ?
                            PeriodicInvestement.fiscalModel.financialRevenuTaxes.net(averageInterestRate) :
                            averageInterestRate)
            default:
                // dans tous les autres cas: pas de charges sociales prélevées à la source anuellement (capitalisation et taxation à la sortie)
                return averageInterestRate
        }
    }
    // état de référence à partir duquel est calculé l'état courant
    var refState: State!

    // MARK: - Initializers
    
    public init(name             : String,
                note             : String,
                type             : InvestementKind,
                firstYear        : Int,
                lastYear         : Int,
                interestRateType : InterestRateKind,
                initialValue     : Double = 0.0,
                initialInterest  : Double = 0.0,
                yearlyPayement   : Double = 0.0,
                yearlyCost       : Double = 0.0) {
        self.name             = name
        self.note             = note
        self.type             = type
        self.firstYear        = firstYear
        self.lastYear         = lastYear
        self.interestRateType = interestRateType
        self.initialValue     = initialValue
        self.initialInterest  = initialInterest
        self.yearlyPayement   = yearlyPayement
        self.yearlyCost       = yearlyCost
        self.refState         = State(firstYear         : firstYear,
                                      initialInterest   : initialInterest,
                                      initialInvestment : initialValue - initialInterest)
    }
    
    // MARK: - Methods
    
    /// Remettre l'état courant à sa valeur initiale
    public mutating func resetReferenceState() {
        self.refState = State(firstYear         : firstYear,
                              initialInterest   : initialInterest,
                              initialInvestment : initialValue - initialInterest)
    }
    
    /// Versement annuel, frais de versement inclus
    /// - Parameter year: année
    /// - Returns: versement, frais de versement inclus
    /// - Note: Les première et dernière années sont inclues
    public func yearlyTotalPayement(atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0
        }
        guard year >= refState.firstYear else {
            customLog.log(level: .error,
                          "L'année d'évaluation \(year) est < à l'année de référence \(refState.firstYear)")
            fatalError()
        }
        return yearlyPayement + yearlyCost
    }
    
    /// Valeur capitalisée à la date spécifiée
    /// - Parameter year: fin de l'année
    /// - Note: Les première et dernière années sont inclues
    public func value (atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0.0
        }
        guard year >= refState.firstYear else {
            customLog.log(level: .error,
                          "L'année d'évaluation \(year) est < à l'année de référence \(refState.firstYear)")
            fatalError()
        }
        return try! futurValue(payement     : yearlyPayement,
                               interestRate : averageInterestRateNet/100,
                               nbPeriod     : year - refState.firstYear,
                               initialValue : refState.initialValue)
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    /// - Warning: les assurance vie ne sont pas inclues car hors succession
    /// - Note: Les première et dernière années sont inclues
    public func ownedValue(by ownerName      : String,
                           atEndOf year      : Int,
                           evaluationContext : EvaluationContext) -> Double {
        // cas particuliers
        switch evaluationContext {
            case .legalSuccession:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // les assurance vie ne sont pas inclues car hors succession
                        return 0
                        
                    default:
                        // le défunt est-il usufruitier ?
                        if ownership.hasAnUsufructOwner(named: ownerName) {
                            // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                            // l'usufruit n'est donc pas intégré à la masse successorale du défunt
                            return 0
                        }
                        // pas de décote
                }
                
            case .lifeInsuranceSuccession, .lifeInsuranceTransmission:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // pas de décote
                        break

                    default:
                        // on recherche uniquement les assurances vies
                        return 0
                }
                
            case .ifi, .isf, .patrimoine:
                // pas de décote
                break
        }
        
        // prendre la valeur totale du bien sans aucune décote
        let evaluatedValue = value(atEndOf: year)
        
        // calculer la part de propriété
        let value = evaluatedValue == 0 ? 0 : ownership.ownedValue(by                : ownerName,
                                                                   ofValue           : evaluatedValue,
                                                                   atEndOf           : year,
                                                                   evaluationContext : evaluationContext)
        return value
    }
    
    /// Intérêts capitalisés à la date spécifiée
    /// - Parameter year: fin de l'année
    /// - Note: Les première et dernière années sont inclues
    public func cumulatedInterests(atEndOf year: Int) -> Double {
        guard (firstYear...lastYear).contains(year) else {
            return 0.0
        }
        guard year >= refState.firstYear else {
            customLog.log(level: .error,
                          "L'année d'évaluation \(year) est < à l'année de référence \(refState.firstYear)")
            fatalError()
        }
        return refState.initialInterest +
            value(atEndOf: year) - (refState.initialValue + yearlyPayement * Double(year - refState.firstYear))
    }
    
    /// valeur liquidative à la date de liquidation
    /// - Parameter year: fin de l'année
    /// - Returns:
    ///   - 0 si `year` n'est pas égal à la date de liquidation
    ///   - revenue : produit de la vente
    ///   - interests : intérêts bruts avant prélèvements sociaux et IRPP
    ///   - netInterests : intérêts nets de prélèvements sociaux
    ///   - taxableInterests : intérêts nets de prélèvements sociaux et taxables à l'IRPP
    ///   - socialTaxes : prélèvements sociaux
    /// - Note: Les première et dernière années sont inclues
    public func liquidatedValue (atEndOf year: Int)
    -> (revenue              : Double,
        interests            : Double,
        netInterests         : Double,
        taxableIrppInterests : Double,
        socialTaxes          : Double) {
        guard year == lastYear else {
            return (0.0, 0.0, 0.0, 0.0, 0.0)
        }
        guard year >= refState.firstYear else {
            customLog.log(level: .error,
                          "L'année d'évaluation \(year) est < à l'année de référence \(refState.firstYear)")
            fatalError()
        }
        let cumulatedInterest = cumulatedInterests(atEndOf: year)
        var netInterests     : Double
        var taxableInterests : Double
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // Si les intérêts sont prélevés au fil de l'eau on les prélève pas à la liquidation
                netInterests     = (periodicSocialTaxes ? cumulatedInterest : PeriodicInvestement.fiscalModel.financialRevenuTaxes.net(cumulatedInterest))
                taxableInterests = netInterests
            case .pea:
                netInterests     = PeriodicInvestement.fiscalModel.financialRevenuTaxes.net(cumulatedInterest)
                taxableInterests = 0.0
            case .other:
                netInterests     = PeriodicInvestement.fiscalModel.financialRevenuTaxes.net(cumulatedInterest)
                taxableInterests = netInterests
        }
        return (revenue              : value(atEndOf: year),
                interests            : cumulatedInterest,
                netInterests         : netInterests,
                taxableIrppInterests : taxableInterests,
                socialTaxes          : cumulatedInterest - netInterests)
    }

    /// Fractionnement  d'un retrait entre: versements cumulés et intérêts cumulés
    /// - Parameter amount: montant du retrait
    func split(removal amount : Double,
               atEndOf year   : Int) -> (investment: Double, interest: Double) {
        guard year >= refState.firstYear else {
            customLog.log(level: .error,
                          "L'année d'évaluation \(year) est < à l'année de référence \(refState.firstYear)")
            fatalError()
        }
        let currentValue     = value(atEndOf: year)
        let currentInterests = cumulatedInterests(atEndOf: year)
        let deltaInterest   = amount * (currentInterests / currentValue)
        let deltaInvestment = amount - deltaInterest
        return (deltaInvestment, deltaInterest)
    }
    
    /// Retirer les capitaux décès de `decedentName` de l'assurance vie
    /// si l'AV n'est pas démembrée et si `decedentName` est un des PP
    /// - Warning: les droits de propriété ne sont PAS mis à jour en conséquence
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - year: année du décès
    public mutating func withdrawLifeInsuranceCapitalDeces(of decedentName : String,
                                                           atEndOf year: Int) {
        guard isLifeInsurance else {
            return
        }
        guard !ownership.isDismembered else {
            return
        }
        guard ownership.hasAFullOwner(named: decedentName) else {
            // le défunt n'a aucun droit de propriété sur le bien
            return
        }
        guard year >= refState.firstYear else {
            let firstYear = refState.firstYear
            customLog.log(level: .error,
                          "L'année d'évaluation \(year) est < à l'année de référence \(firstYear)")
            fatalError()
        }

        // capitaux décès
        let ownedValueDecedent = ownedValue(by                : decedentName,
                                            atEndOf           : year,
                                            evaluationContext : .lifeInsuranceSuccession)
        
        // les capitaux décès sont retirés de l'assurance vie pour être distribuée en cash
        // décrémenter le capital (versement et intérêts) du montant retiré
        let withdrawal = split(removal: ownedValueDecedent, atEndOf: year)
        refState = State(firstYear         : year,
                         initialInterest   : refState.initialInterest - withdrawal.interest,
                         initialInvestment : refState.initialInvestment - withdrawal.investment)
    }
}

// MARK: - Extensions

extension PeriodicInvestement: Comparable {
    public static func < (lhs: PeriodicInvestement, rhs: PeriodicInvestement) -> Bool {
        return (lhs.name < rhs.name)
    }
}

extension PeriodicInvestement: CustomStringConvertible {
    public var description: String {
        """
        INVESTISSEMENT PERIODIQUE: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Type:\(type.description.withPrefixedSplittedLines("  "))
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
        - Valeur:              \(value(atEndOf: Date.now.year).€String)
        - Première année:      \(firstYear) dernière année: \(lastYear)
        - Valeur initiale:     \(initialValue.€String) dont intérêts: \(initialInterest.€String)
        - Valeur de référence: \(refState.initialValue.€String) dont intérêts: \(refState.initialInterest.€String)
        - Versement annuel net de frais:  \(yearlyPayement.€String) Frais sur versements annuels: \(yearlyCost.€String)
        - Valeur liquidative:  \(value(atEndOf: lastYear).€String) Intérêts cumulés: \(cumulatedInterests(atEndOf: lastYear).€String)
        - \(interestRateType)
        - Taux d'intérêt net d'inflation avant prélèvements sociaux:   \(averageInterestRate) %
        - Taux d'intérêt net d'inflation, net de prélèvements sociaux: \(averageInterestRateNet) %
        """
    }
}
