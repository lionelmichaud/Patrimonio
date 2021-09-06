//
//  KpiComputer.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 05/09/2021.
//

import Foundation
import os
import Statistics
import FamilyModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.KpiComputer")

struct KpiComputer {

    fileprivate func setKpiValue(kpiEnum        : SimulationKPIEnum,
                                 value          : Double,
                                 kpiDictionnary : inout KpiDictionary,
                                 kpiResults     : inout KpiResultsDictionary,
                                 simulationMode : SimulationModeEnum) {
        kpiDictionnary[kpiEnum]!.record(value, withMode: simulationMode)
        kpiResults[kpiEnum] =
            KpiResult(value              : value,
                      objectiveIsReached : kpiDictionnary[kpiEnum]!.objectiveIsReached(for: value))
    }

    /// Mémorise le niveau le + bas atteint par les actifs financiers NETS (hors immobilier physique) des ADULTS au cours du run
    /// - Note:
    ///   - Les biens sont sont évalués à leur valeur selon la méthode de calcul des préférences utilisateur
    /// - Parameters:
    ///   - kpiDictionnary: les KPI à utiliser
    ///   - simulationMode: mode de simluation en cours
    ///   - balanceArray: les bilans annuels
    ///   - currentRunKpiResults: valeur des KPIs pour le run courant
    fileprivate func computeMinimumAssetKpiValue(withKPIs kpiDictionnary       : inout KpiDictionary,
                                                 withMode simulationMode       : SimulationModeEnum,
                                                 withBalanceArray balanceArray : BalanceSheetArray,
                                                 currentRunKpiResults          : inout KpiResultsDictionary) {
        let minBalanceSheetLine = balanceArray.min { a, b in
            a.netAdultsFinancialAssets < b.netAdultsFinancialAssets
        }
        // KPI 3: mémoriser le minimum d'actif financier net des adultes au cours du temps
        setKpiValue(kpiEnum        : .minimumAdultsAssetExcludinRealEstates,
                    value          : minBalanceSheetLine!.netAdultsFinancialAssets,
                    kpiDictionnary : &kpiDictionnary,
                    kpiResults     : &currentRunKpiResults,
                    simulationMode : simulationMode)
    }

    /// Gérer les KPI quand il n'y a plus de Cash => on arrête la simulation et on calcule la valeur des KPIs
    /// - Note:
    ///   - Les biens sont sont évalués à leur valeur selon la méthode de calcul des préférences utilisateur
    /// - Parameters:
    ///   - year: année du run courant
    ///   - family: la famille dont il faut faire le bilan
    ///   - kpiDictionnary: les KPI à utiliser
    ///   - currentRunKpiResults: valeur des KPIs pour le run courant
    ///   - simulationMode: mode de simluation en cours
    ///   - withbalanceSheetLine: bilan de l'année
    fileprivate func computeKpisAtZeroCashAvailable // swiftlint:disable:this function_parameter_count
    (year                    : Int,
     withFamily family       : Family,
     withKPIs kpiDictionnary : inout KpiDictionary,
     currentRunKpiResults    : inout KpiResultsDictionary,
     withMode simulationMode : SimulationModeEnum,
     withBalanceSheetLine    : BalanceSheetLine?) {
        customLog.log(level: .info, "Arrêt de la construction de la table en \(year, privacy: .public) de Comptes sociaux: à court de cash dans \(Self.self, privacy: .public)")

        // Actif Net (hors immobilier physique)
        let netFinancialAssets = withBalanceSheetLine?.netAdultsFinancialAssets ?? 0
        customLog.log(level: .info, "netFinancialAssets: \(netFinancialAssets.k€String, privacy: .public)")

        // mémoriser le montant de l'Actif financier Net (hors immobilier physique)
        switch family.nbOfAdultAlive(atEndOf: year) {
            case 2:
                // il reste 2 adultes vivants
                ()

            case 1:
                // il reste 1 seul adulte vivant
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    // un des deux adulte est décédé cette année
                    setKpiValue(kpiEnum        : .assetAt1stDeath,
                                value          : netFinancialAssets,
                                kpiDictionnary : &kpiDictionnary,
                                kpiResults     : &currentRunKpiResults,
                                simulationMode : simulationMode)
                }

            case 0:
                // il ne plus d'adulte vivant
                ()

            default:
                // ne devrait jamais se produire
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year), privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year)) dans \(Self.self)")
        }
        /// KPI n°3 : on est arrivé à la fin de la simulation car il n'y a plus de revenu généré par les Free Investements
        /// mais il peut éventuellement rester d'autres actifs (immobilier de rendement...)
        // TODO: - il faudrait définir un KPI spécifique "plus assez de revenu pour survivre" au lieu de faire comme s'il ne restait plus d'actif net
        setKpiValue(kpiEnum        : .minimumAdultsAssetExcludinRealEstates,
                    value          : 0,
                    kpiDictionnary : &kpiDictionnary,
                    kpiResults     : &currentRunKpiResults,
                    simulationMode : simulationMode)
    }

    /// Gérer les KPI n°1, 2, 3 au décès de l'un ou des 2 conjoints
    /// - Note:
    ///   - Les biens sont sont évalués à leur valeur selon la méthode de calcul des préférences utilisateur
    /// - Parameters:
    ///   - year: année du run courant
    ///   - family: la famille dont il faut faire le bilan
    ///   - kpiDictionnary: les KPI à utiliser
    ///   - currentRunKpiResults: valeur des KPIs pour le run courant
    ///   - simulationMode: mode de simluation en cours
    ///   - balanceSheetLineBeforeTransmission: dernier Bilan avant transmissions
    ///   - balanceSheetLineAfterTransmission: Bilan après transmissions
    fileprivate func computeKpisAtDeath (year                               : Int, // swiftlint:disable:this function_parameter_count
                                         withFamily family                  : Family,
                                         withKPIs kpiDictionnary            : inout KpiDictionary,
                                         currentRunKpiResults               : inout KpiResultsDictionary,
                                         withMode simulationMode            : SimulationModeEnum,
                                         balanceSheetLineBeforeTransmission : BalanceSheetLine?,
                                         balanceSheetLineAfterTransmission  : BalanceSheetLine) {
        // Dernier Actif Net (après transmission en cas de décès dans l'année) (hors immobilier physique)
        let netFinancialAssetsAfterTransmission = balanceSheetLineAfterTransmission.netAdultsFinancialAssets

        // Actif Net précédent (avant transmission en cas de décès dans l'année) (hors immobilier physique))
        let netFinancialAssetsBeforeTransmission = balanceSheetLineBeforeTransmission?.netAdultsFinancialAssets ?? netFinancialAssetsAfterTransmission

        switch family.nbOfAdultAlive(atEndOf: year) {
            case 1:
                /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net (hors immobilier physique) du conjoint survivant après transmission
                setKpiValue(kpiEnum        : .assetAt1stDeath,
                            value          : netFinancialAssetsAfterTransmission,
                            kpiDictionnary : &kpiDictionnary,
                            kpiResults     : &currentRunKpiResults,
                            simulationMode : simulationMode)

            case 0:
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                    // mémoriser le montant de l'Actif Net (hors immobilier physique) des parents avant transmission
                    setKpiValue(kpiEnum        : .assetAt1stDeath,
                                value          : netFinancialAssetsBeforeTransmission,
                                kpiDictionnary : &kpiDictionnary,
                                kpiResults     : &currentRunKpiResults,
                                simulationMode : simulationMode)
                }
                /// KPI n°2: décès du second conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net (hors immobilier physique) des parents avant transmission
                setKpiValue(kpiEnum        : .assetAt2ndtDeath,
                            value          : netFinancialAssetsBeforeTransmission,
                            kpiDictionnary : &kpiDictionnary,
                            kpiResults     : &currentRunKpiResults,
                            simulationMode : simulationMode)
                /// KPI n°3 : on est arrivé à la fin de la simulation
                // rechercher le minimum d'actif financier au cours du temps (hors immobilier physique)
                computeMinimumAssetKpiValue(withKPIs             : &kpiDictionnary,
                                            withMode             : simulationMode,
                                            withBalanceArray: <#BalanceSheetArray#>,
                                            currentRunKpiResults : &currentRunKpiResults)

            default:
                // ne devrait jamais se produire
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year), privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year)) dans  \(Self.self)")
        }
    }

}
