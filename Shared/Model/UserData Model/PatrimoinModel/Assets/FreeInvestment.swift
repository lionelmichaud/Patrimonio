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

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.FreeInvestement")

enum FreeInvestementError: Error {
    case IlegalOperation
}

typealias FreeInvestmentArray = ArrayOfNameableValuable<FreeInvestement>

// MARK: - Placement à versement et retrait variable et à taux fixe

/// Placement à versement et retrait libres et à taux fixe
/// Les intérêts sont capitalisés lors de l'appel à capitalize()
// conformité à BundleCodable nécessaire pour les TU; sinon Codable suffit
struct FreeInvestement: Identifiable, Codable, FinancialEnvelop {
    
    // nested types
    
    /// Situation annuelle de l'investissement
    struct State: Codable, Equatable {
        var year       : Int
        var interest   : Double // portion of interests included in the Value
        var investment : Double // portion of investment included in the Value
        var value      : Double { interest + investment } // valeur totale
    }
    
    // MARK: - Static Properties
    
    static var defaultFileName : String = "FreeInvestement.json"
    
    private static var simulationMode: SimulationModeEnum = .deterministic
    // dependencies
    private static var economyModel : EconomyModelProviderProtocol = Economy.model
    private static var fiscalModel  : Fiscal.Model                 = Fiscal.model

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
    static func setEconomyModelProvider(_ economyModel : EconomyModelProviderProtocol) {
        FreeInvestement.economyModel = economyModel
    }
    
    /// Dependency Injection: Setter Injection
    static func setFiscalModelProvider(_ fiscalModel : Fiscal.Model) {
        FreeInvestement.fiscalModel = fiscalModel
    }
    
    static func setSimulationMode(to thisMode: SimulationModeEnum) {
        FreeInvestement.simulationMode = thisMode
    }
    
    private static func rates(in year : Int)
    -> (securedRate : Double,
        stockRate   : Double) {
        FreeInvestement.economyModel.rates(in                 : year,
                                           withMode           : simulationMode,
                                           simulateVolatility : UserSettings.shared.simulateVolatility)
    }

    // MARK: - Properties

    var id                   = UUID()
    var name                 : String
    var note                 : String
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    var ownership: Ownership = Ownership()

    /// Type de l'investissement
    var type: InvestementKind

    /// Type de taux de rendement
    var interestRateType: InterestRateKind

    /// Rendement en % avant charges sociales si prélevées à la source annuellement [0, 100%]
    var averageInterestRate  : Double {
        switch interestRateType {
            case .contractualRate(let fixedRate):
                // taux contractuel fixe
                return fixedRate - FreeInvestement.inflation
                
            case .marketRate(let stockRatio):
                // taux de marché variable
                let stock = stockRatio / 100.0
                // taux d'intérêt composite fonction de la composition du portefeuille
                let rate =
                    stock * FreeInvestement.rates.averageStockRate
                    + (1.0 - stock) * FreeInvestement.rates.averageSecuredRate
                return rate - FreeInvestement.inflation
        }
    }

    /// Rendement en % après charges sociales si prélevées à la source annuellement [0, 100%]
    var averageInterestRateNet: Double {
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

    /// Dernière constitution du capital connue
    var lastKnownState: State {
        didSet {
            resetCurrentState()
        }
    }

    /// Constitution du capital à l'instant présent
    private var currentState: State

    /// Intérêts cumulés au cours du temps jusqu'à l'instant présent
    private var cumulatedInterests: Double {
        currentState.interest
    }
    
    // MARK: - Initialization

    init(year             : Int,
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
        self.currentState     = self.lastKnownState
    }
    
    // MARK: - Methods

    /// Taux d'intérêt annuel en % net de  charges sociales si prélevées à la source annuellement
    /// - Parameter idx: [0, nb d'années simulées - 1]
    /// - Returns: Taux d'intérêt annuel en % [0, 100%]
    private func interestRateNet(in year: Int) -> Double {
        switch interestRateType {
            case .contractualRate(let fixedRate):
                // taux contractuel fixe
                return fixedRate - FreeInvestement.inflation
                
            case .marketRate(let stockRatio):
                // taux de marché variable
                let stock = stockRatio / 100.0
                let rates = FreeInvestement.rates(in: year)
                // taux d'intérêt composite fonction de la composition du portefeuille
                let rate = stock * rates.stockRate + (1.0 - stock) * rates.securedRate
                return rate - FreeInvestement.inflation
        }
    }
    
    /// Intérêts annuels en € du capital accumulé à l'instant présent
    /// - Parameter idx: [0, nb d'années simulées - 1]
    /// - Returns: Intérêts annuels en €
    private func yearlyInterest(in year: Int) -> Double {
        currentState.value * interestRateNet(in: year) / 100.0
    }
    
    /// Fractionnement d'un retrait entre: versements cumulés et intérêts cumulés
    /// - Parameter amount: montant du retrait
    func split(removal amount: Double) -> (investement: Double, interest: Double) {
        let deltaInterest   = amount * (currentState.interest / currentState.value)
        let deltaInvestment = amount - deltaInterest
        return (deltaInvestment, deltaInterest)
    }
    
    /// somme des versements + somme des intérêts
    func value(atEndOf year: Int) -> Double {
        guard year == self.currentState.year else {
            // extrapoler la valeur à partir de la situation initiale avec un taux constant moyen
            return try! futurValue(payement     : 0,
                                   interestRate : averageInterestRateNet/100,
                                   nbPeriod     : year - lastKnownState.year,
                                   initialValue : lastKnownState.value)
        }
        // valeur de la dernière année simulée
        return currentState.value
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    /// - Warning: les assurance vie ne sont pas inclues car hors succession
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        // cas particuliers
        switch evaluationMethod {
            case .legalSuccession:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // les assurance vie ne sont pas inclues car hors succession légale
                        return 0

                    default:
                        // le défunt est-il usufruitier ?
                        if ownership.hasAnUsufructOwner(named: ownerName) {
                            // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                            // l'usufruit n'est donc pas intégré à la masse successorale du défunt
                            return 0
                        }
                        // pas de décote
                        ()
                }

            case .lifeInsuranceSuccession:
                // le bien est-il une assurance vie ?
                switch type {
                    case .lifeInsurance:
                        // pas de décote
                        ()
                        
                    default:
                        // on recherche uniquement les assurances vies
                        return 0
                }
                
            case .ifi, .isf, .patrimoine:
                // pas de décote
                ()
                
        }

        // cas général
        // prendre la valeur totale du bien sans aucune décote
        let evaluatedValue = value(atEndOf: year)

        // calculer la part de propriété
        let value = evaluatedValue == 0 ? 0 : ownership.ownedValue(by               : ownerName,
                                                                   ofValue          : evaluatedValue,
                                                                   atEndOf          : year,
                                                                   evaluationMethod : evaluationMethod)
        return value
    }
    
    /// Réaliser un versement
    /// - Parameter amount: montant du versement
    mutating func add(_ amount: Double) {
        currentState.investment += amount
    }
    
    /// Effectuer un retrait de `netAmount` NET de charges sociales pour le compte d'un débiteur nommé `name`.
    /// - Note:
    ///     Si `name` != nil :
    ///     - Tient compte des droits de propriété du débiteur. Le retrait n'est alors autorisé que si le débiteur possède une part de la PP du bien.
    ///     - Autorise le retrait dans la limite de la part de propriété du débiteur.
    ///     - Met à jour la part de propriété du débiteur en conséquence.
    /// - Returns:
    ///     - revenue:             retrait net de charges sociales réellement obtenu (= netAmount si le capital est suffisant, moins sinon)
    ///     - interests:           intérêts bruts avant charges sociales
    ///     - netInterests:        intérêts nets de charges sociales
    ///     - taxableInterests:    part des netInterests imposable à l'IRPP
    ///     - socialTaxes:         charges sociales sur les intérêts
    /// - Parameters:
    ///   - netAmount: retrait net de charges sociales souhaité
    ///   - name: nom du débiteur ou nil
    mutating func remove(netAmount : Double,
                         for name  : String = "")
    -> (revenue          : Double,
        interests        : Double,
        netInterests     : Double,
        taxableInterests : Double,
        socialTaxes      : Double) {
        let zero = (revenue: 0.0, interests: 0.0, netInterests: 0.0, taxableInterests: 0.0, socialTaxes: 0.0)

        guard currentState.value > 0.0 else {
            // le compte est vide: on ne retire rien
            return zero
        }
        
        var updateOwnership = false
        var maxPermitedValue : Double
        var ownedValueBefore : Double            = 0
        var theOwnedValues   : [String : Double] = [:]
        if name != "" {
            guard ownership.hasAFullOwner(named: name) else {
                // le débiteur n'est pas un PP: on ne retire rien
                return zero
            }
            updateOwnership = ownership.fullOwners.count != 1
            if updateOwnership {
                theOwnedValues = ownedValues(atEndOf          : currentState.year,
                                             evaluationMethod : .patrimoine)
                ownedValueBefore = theOwnedValues[name]!
                maxPermitedValue = min(currentState.value,
                                       ownedValueBefore)
            } else {
                maxPermitedValue = currentState.value
            }
        } else {
            maxPermitedValue = currentState.value
        }
        
        var revenue = netAmount
        var brutAmount       : Double
        var brutAmountSplit  : (investement  : Double, interest  : Double)
        var netInterests     : Double // intérêts nets de charges sociales
        var taxableInterests : Double // part imposable à l'IRPP des intérêts nets de charges sociales
        var socialTaxes      : Double // charges sociales sur les intérêts

        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = (periodicSocialTaxes ? netAmount : FreeInvestement.fiscalModel.financialRevenuTaxes.brut(netAmount))
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > maxPermitedValue {
                    brutAmount = maxPermitedValue
                    revenue    = (periodicSocialTaxes ? brutAmount : FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmount))
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                if periodicSocialTaxes {
                    netInterests = brutAmountSplit.interest
                    socialTaxes  = 0.0
                } else {
                    netInterests = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmountSplit.interest)
                    socialTaxes  = FreeInvestement.fiscalModel.financialRevenuTaxes.socialTaxes(brutAmountSplit.interest)
                }
                // Assurance vie: les plus values sont imposables à l'IRPP (mais avec une franchise applicable à la totalité des interets retirés dans l'année: calculé ailleurs)
                taxableInterests = netInterests

            case .pea:
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = FreeInvestement.fiscalModel.financialRevenuTaxes.brut(netAmount)
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > maxPermitedValue {
                    brutAmount = maxPermitedValue
                    revenue    = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmount)
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                netInterests = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmountSplit.interest)
                socialTaxes  = FreeInvestement.fiscalModel.financialRevenuTaxes.socialTaxes(brutAmountSplit.interest)
                // PEA: les plus values ne sont pas imposables à l'IRPP
                taxableInterests = 0.0

            case .other:
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = FreeInvestement.fiscalModel.financialRevenuTaxes.brut(netAmount)
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > maxPermitedValue {
                    brutAmount = maxPermitedValue
                    revenue    = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmount)
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                netInterests = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmountSplit.interest)
                socialTaxes  = FreeInvestement.fiscalModel.financialRevenuTaxes.socialTaxes(brutAmountSplit.interest)
                // autre cas: les plus values sont totalement imposables à l'IRPP
                taxableInterests = netInterests
        }
        
        // décrémenter les intérêts et le capital
        if brutAmount == currentState.value {
            // On a vidé le compte: mettre précisément le compte à 0.0 (attention à l'arrondi sinon)
            currentState.interest   = 0
            currentState.investment = 0
        } else {
            // décrémenter le capital (versement et intérêts) du montant brut retiré pour obtenir le net (de charges sociales) souhaité
            currentState.interest   -= brutAmountSplit.interest
            currentState.investment -= brutAmountSplit.investement
        }
        
        // actualiser les droits de propriété en tenant compte du retrait qui va être fait
        if updateOwnership {
            let ownedValueAfter = ownedValueBefore - brutAmount
            print("Avant   = \(ownedValueBefore.k€String)")
            print("Retrait = \(brutAmount.k€String)")
            print("Après   = \(ownedValueAfter.k€String)")
            print("Ownership avant = \n", String(describing: ownership))
            if ownedValueAfter != 0 {
                theOwnedValues[name] = ownedValueAfter
                ownership.fullOwners = []
                theOwnedValues.forEach { (name: String, value: Double) in
                    ownership.fullOwners.append(Owner(name     : name,
                                                      fraction : value / currentState.value * 100.0))
                }
            }
            print("Ownership après = \n", String(describing: ownership))
        }

        return (revenue          : revenue,
                interests        : brutAmountSplit.interest,
                netInterests     : netInterests,
                taxableInterests : taxableInterests,
                socialTaxes      : socialTaxes)
    }
    
    /// Capitaliser les intérêts d'une année: à faire une fois par an et apparaissent dans l'année courante
    /// - Note: Si la volatilité est prise en compte dans le modèle économique alors le taux change chaque année
    mutating func capitalize(atEndOf year: Int) throws {
        guard year == currentState.year + 1 else {
            customLog.log(level: .error,
                          "FreeInvestementError.capitalize: capitalisation sur un nombre d'année différent de 1")
            throw FreeInvestementError.IlegalOperation
        }
        currentState.interest += yearlyInterest(in: year)
        currentState.year = year
    }
    
    /// Remettre la valeur courante à la date de fin d'année passée
    mutating func resetCurrentState() {
        // calculer la valeur de currentState à la date de fin d'année passée
        let estimationYear = Date.now.year - 1
        
        if estimationYear == lastKnownState.year {
            currentState = lastKnownState
            
        } else {
            // extrapoler la valeure à partir de la situation initiale
            do {
                let futurVal = try futurValue(payement     : 0,
                                              interestRate : averageInterestRateNet/100,
                                              nbPeriod     : estimationYear - lastKnownState.year,
                                              initialValue : lastKnownState.value)
                currentState = State(year       : estimationYear,
                                     interest   : lastKnownState.interest + (futurVal - lastKnownState.value),
                                     investment : lastKnownState.investment)
            } catch FinancialMathError.negativeNbPeriod {
                // on ne remonte pas le temps
                customLog.log(level: .fault,
                              "estimationYear (\(estimationYear, privacy: .public)) < initialState.year")
                fatalError("estimationYear (\(estimationYear)) < initialState.year (\(lastKnownState.year))")
            } catch {
                customLog.log(level: .fault, "FinancialMathError")
                fatalError("FinancialMathError")
            }
        }
    }
}

// MARK: Extensions
extension FreeInvestement: Comparable {
    static func < (lhs: FreeInvestement, rhs: FreeInvestement) -> Bool {
        return (lhs.name < rhs.name)
    }
}

extension FreeInvestement: CustomStringConvertible {
    var description: String {
        """
        INVESTISSEMENT LIBRE: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Type:\(type.description.withPrefixedSplittedLines("  "))
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
        - Valeur (\(Date.now.year)): \(value(atEndOf: Date.now.year).€String)
        - Etat initial: (year: \(lastKnownState.year), interest: \(lastKnownState.interest.€String), invest: \(lastKnownState.investment.€String), Value: \(lastKnownState.value.€String))
        - Etat courant: (year: \(currentState.year), interest: \(currentState.interest.€String), invest: \(currentState.investment.€String), Value: \(currentState.value.€String))
        - \(interestRateType)
        - Taux d'intérêt net d'inflation avant prélèvements sociaux:   \(averageInterestRate) %
        - Taux d'intérêt net d'inflation, net de prélèvements sociaux: \(averageInterestRateNet) %
        """
    }
}
