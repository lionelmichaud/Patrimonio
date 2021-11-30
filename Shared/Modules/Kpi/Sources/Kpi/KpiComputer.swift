//
//  KpiComputer.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 05/09/2021.
//

import Foundation
import os
import Statistics
import ModelEnvironment
import FamilyModel
import PersonModel
import BalanceSheet
import Succession

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.KpiComputer")

public struct KpiComputer {
    
    // MARK: - Properties
    
    /// SimulationMode: mode de simluation en cours
    private let simulationMode      : SimulationModeEnum
    private let model               : Model
    private let family              : Family
    private var kpiResults          = KpiResultsDictionary()
    /// Résultas du run en cours
    public var currentRunKpiResults : KpiResultsDictionary {
        kpiResults
    }

    // MARK: - Initializer
    
    public init(simulationMode : SimulationModeEnum,
                model          : Model,
                family         : Family) {
        self.simulationMode = simulationMode
        self.model          = model
        self.family         = family
    }
    
    // MARK: - Methods
    
    /// Enregistrer la valeur courante `value` du KPI `kpiEnum` dans son historique du dictionnaire
    /// `kpiDictionnary`de KPIs et dans les résultas du run en cours `kpiResults`
    /// - Parameters:
    ///   - kpiEnum: le KPI
    ///   - value: sa valeur
    ///   - kpiDictionnary: dictionnaire des KPIs contenant les historiques de chaque KPI
    fileprivate mutating func setKpiValue
    (kpiEnum        : KpiEnum,
     value          : Double,
     kpiDictionnary : inout KpiDictionary) {
        // Enregistrer la valeur courante du KPI dans son historique
        kpiDictionnary[kpiEnum]!.record(value, withMode: simulationMode)
        // Enregistrer la valeur courante du KPI dans les résultas du run en cours
        kpiResults[kpiEnum] =
            KpiResult(value              : value,
                      objectiveIsReached : kpiDictionnary[kpiEnum]!.objectiveIsReached(for: value))
    }
    
    fileprivate func successionsChildrenTaxes(for allSuccessions: [Succession]) -> Double {
        var taxes = 0.0
        for succession in allSuccessions {
            for inheritance in succession.inheritances {
                if (family.member(withName: inheritance.successorName) as? Child) != nil {
                    taxes += inheritance.tax
                }
            }
        }
        return taxes
    }
    
    /// Somme des soldes nets de l'héritage reçu par les enfants à chaque décès
    /// - Parameter netChildrenInheritances: soldes nets de l'héritage reçu par les enfants à chaque décès depuis le début du run
    func netChildrenSuccession(_ netChildrenInheritances: [Double]) -> Double {
        netChildrenInheritances.sum()
    }
    
    /// Mémorise le niveau le + bas atteint par les actifs financiers NETS (hors immobilier physique) des ADULTS au cours du run
    /// - Note:
    ///   - Les biens sont sont évalués à leur valeur selon la méthode de calcul des préférences utilisateur
    /// - Parameters:
    ///   - kpiDictionnary: les KPI à utiliser
    ///   - balanceArray: les bilans annuels
    ///   - currentRunKpiResults: valeur des KPIs pour le run courant
    public mutating func computeMinimumAssetKpiValue
    (withKPIs kpiDictionnary       : inout KpiDictionary,
     withBalanceArray balanceArray : BalanceSheetArray) {
        let minBalanceSheetLine = balanceArray.min { a, b in
            a.netAdultsFinancialAssets < b.netAdultsFinancialAssets
        }
        // KPI 3: mémoriser le minimum d'actif financier net des adultes au cours du temps
        setKpiValue(kpiEnum        : .minimumAdultsAssetExcludinRealEstates,
                    value          : minBalanceSheetLine!.netAdultsFinancialAssets,
                    kpiDictionnary : &kpiDictionnary)
    }
    
    /// Calculer les KPI quand il n'y a plus de Cash => on arrête la simulation et on calcule la valeur des KPIs
    /// - Note:
    ///   - Les biens sont sont évalués selon la méthode de calcul des préférences utilisateur
    ///   - KPI calculés:
    ///     - .assetAt1stDeath
    ///     - .minimumAdultsAssetExcludinRealEstates
    /// - Parameters:
    ///   - year: année du run courant
    ///   - kpiDictionnary: les KPI à utiliser
    ///   - currentRunKpiResults: valeur des KPIs pour le run courant
    ///   - withbalanceSheetLine: bilan de l'année
    public mutating func computeKpisAtZeroCashAvailable
    (year                    : Int,
     withKPIs kpiDictionnary : inout KpiDictionary,
     withBalanceSheetLine    : BalanceSheetLine?) {
        customLog.log(level: .info, "Arrêt de la construction de la table en \(year, privacy: .public) de Comptes sociaux: à court de cash dans \(Self.self, privacy: .public)")
        
        // Actif Net (hors immobilier physique)
        let netFinancialAssets = withBalanceSheetLine?.netAdultsFinancialAssets ?? 0
        customLog.log(level: .info, "netFinancialAssets: \(netFinancialAssets.k€String, privacy: .public)")
        
        // mémoriser le montant de l'Actif financier Net (hors immobilier physique)
        switch family.nbOfAdultAlive(atEndOf: year) {
            case 2:
                // il reste 2 adultes vivants
                break
                
            case 1:
                // il reste 1 seul adulte vivant
                /// KPI .assetAt1stDeath
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    // un des deux adulte est décédé cette année
                    setKpiValue(kpiEnum        : .assetAt1stDeath,
                                value          : netFinancialAssets,
                                kpiDictionnary : &kpiDictionnary)
                }
                
            case 0:
                // il ne plus d'adulte vivant
                break
                
            default:
                // ne devrait jamais se produire
                let nbOfAdultAlive = family.nbOfAdultAlive(atEndOf: year)
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(nbOfAdultAlive, privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(nbOfAdultAlive) dans \(Self.self)")
        }
        /// KPI .minimumAdultsAssetExcludinRealEstates :
        // on est arrivé à la fin de la simulation car il n'y a plus de revenu généré par les Free Investements
        // mais il peut éventuellement rester d'autres actifs (immobilier de rendement...)
        // TODO: - il faudrait définir un KPI spécifique "plus assez de revenu pour survivre" au lieu de faire comme s'il ne restait plus d'actif net
        setKpiValue(kpiEnum        : .minimumAdultsAssetExcludinRealEstates,
                    value          : 0,
                    kpiDictionnary : &kpiDictionnary)
    }
    
    /// Calculer les KPI au décès de l'un ou des 2 conjoints
    /// - Note:
    ///   - Les biens sont sont évalués selon la méthode de calcul des préférences utilisateur
    ///   - KPI calculés:
    ///     - .assetAt1stDeath
    ///     - .successionTaxesAt1stDeath
    ///     - .assetAt2ndtDeath
    ///     - .successionTaxesAt2ndDeath
    ///     - .netSuccessionAt2ndDeath
    ///     - .minimumAdultsAssetExcludinRealEstates
    /// - Parameters:
    ///   - year: année du run courant
    ///   - kpiDictionnary: les KPI à utiliser
    ///   - currentRunKpiResults: valeur des KPIs pour le run courant
    ///   - balanceArray: les bilans annuels
    ///   - balanceSheetLineAfterTransmission: Bilan après transmissions
    ///   - allSuccessions: ensemble des succssions ayant eu lieu à ce moment de la simulation
    ///   - netChildrenInheritances: soldes nets de l'héritage reçu par les enfants à chaque décès
    public mutating func computeKpisAtDeath // swiftlint:disable:this function_parameter_count
    (year                               : Int,
     withKPIs kpiDictionnary            : inout KpiDictionary,
     withBalanceArray balanceArray      : BalanceSheetArray,
     balanceSheetLineAfterTransmission  : BalanceSheetLine,
     allSuccessions                     : [Succession],
     netChildrenInheritances            : [Double]) {
        // Dernier Actif Net (après transmission en cas de décès dans l'année) (hors immobilier physique)
        let netFinancialAssetsAfterTransmission = balanceSheetLineAfterTransmission.netAdultsFinancialAssets
        
        // Actif Net précédent (avant transmission en cas de décès dans l'année) (hors immobilier physique))
        let netFinancialAssetsBeforeTransmission = balanceArray.last?.netAdultsFinancialAssets ?? netFinancialAssetsAfterTransmission
        
        switch family.nbOfAdultAlive(atEndOf: year) {
            case 1: // il reste un conjoint survivant
                /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net (hors immobilier physique) du conjoint survivant après transmission
                setKpiValue(kpiEnum        : .assetAt1stDeath,
                            value          : netFinancialAssetsAfterTransmission,
                            kpiDictionnary : &kpiDictionnary)
                /// KPI n°5: décès du premier conjoint et mémoriser la valeur du KPI
                // mémoriser le montant des droits de succession des enfants au 1er décès
                let taxes = successionsChildrenTaxes(for: allSuccessions)
                setKpiValue(kpiEnum        : .successionTaxesAt1stDeath,
                            value          : taxes,
                            kpiDictionnary : &kpiDictionnary)
                
            case 0: // il ne reste plus de conjoint survivant
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                    // mémoriser le montant de l'Actif Net (hors immobilier physique) des parents avant transmission
                    setKpiValue(kpiEnum        : .assetAt1stDeath,
                                value          : netFinancialAssetsBeforeTransmission,
                                kpiDictionnary : &kpiDictionnary)
                    
                    /// KPI n°6: décès du premier conjoint et mémoriser la valeur du KPI
                    // mémoriser le montant des droits de succession des enfants au dernier décès
                    let taxes = successionsChildrenTaxes(for: allSuccessions)
                    setKpiValue(kpiEnum        : .successionTaxesAt1stDeath,
                                value          : taxes,
                                kpiDictionnary : &kpiDictionnary)
                }
                /// KPI n°2: décès du second conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net (hors immobilier physique) des parents avant transmission
                setKpiValue(kpiEnum        : .assetAt2ndtDeath,
                            value          : netFinancialAssetsBeforeTransmission,
                            kpiDictionnary : &kpiDictionnary)
                
                /// KPI n°3 : on est arrivé à la fin de la simulation
                // rechercher le minimum d'actif financier au cours du temps (hors immobilier physique)
                computeMinimumAssetKpiValue(withKPIs             : &kpiDictionnary,
                                            withBalanceArray     : balanceArray)
                
                /// KPI n°4: décès du second conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Héritage total net des enfants
                let heritage = netChildrenSuccession(netChildrenInheritances)
                setKpiValue(kpiEnum        : .netSuccessionAt2ndDeath,
                            value          : heritage,
                            kpiDictionnary : &kpiDictionnary)

                /// KPI n°6: décès du second conjoint et mémoriser la valeur du KPI
                // mémoriser le montant des droits de succession des enfants au dernier décès
                let taxes = successionsChildrenTaxes(for: allSuccessions)
                setKpiValue(kpiEnum        : .successionTaxesAt2ndDeath,
                            value          : taxes,
                            kpiDictionnary : &kpiDictionnary)

            default:
                // ne devrait jamais se produire
                let nbOfAdultAlive = family.nbOfAdultAlive(atEndOf: year)
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(nbOfAdultAlive, privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(nbOfAdultAlive) dans  \(Self.self)")
        }
    }
}
