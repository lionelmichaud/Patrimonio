import Foundation
import os
import AppFoundation
import Statistics
import Files
import ModelEnvironment
import Succession
import LifeExpense
import PatrimoineModel
import FamilyModel
import BalanceSheet
import SimulationLogger

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts")

/// Combinaisons possibles de séries sur le graphique de CashFlow
enum CashCombination: String, PickableEnumP {
    case revenues = "Revenu"
    case expenses = "Dépense"
    case both     = "Tout"
    
    var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Comptes sociaux

/// Comptes sociaux: Table de Compte de résultat annuels + Bilans annuels
struct SocialAccounts {
    
    // MARK: - Properties
    
    var cashFlowArray = CashFlowArray()
    var balanceArray  = BalanceSheetArray()
    var firstYear     = Date.now.year
    var lastYear      = Date.now.year
    // les successions légales
    var legalSuccessions   : [Succession] = []
    // les transmissions d'assurances vie
    var lifeInsSuccessions : [Succession] = []
    
    // MARK: - Computed Properties
    
    // MARK: - Methods
    
    // MARK: - Construction de la table des comptes sociaux = Bilan + CashFlow
    
    /// Construire la table de comptes sociaux au fil des années
    /// - Parameters:
    ///   - run: numéro du run en cours de calcul
    ///   - nbOfYears: nombre d'années à construire
    ///   - family: la famille dont il faut faire le bilan
    ///   - expenses: les dépenses de la famille
    ///   - patrimoine: le patrimoine de la famille
    ///   - kpis: les KPI à utiliser et à dont il faut mettre à jour l'histogramme pendant le run
    ///   - simulationMode: mode de simluation en cours
    ///   - model: modèle à utiliser
    /// - Returns: Résultats obtenus pour les KPI
    mutating func build(run                       : Int, // swiftlint:disable:this function_parameter_count
                        nbOfYears                 : Int,
                        withFamily family         : Family,
                        withExpenses expenses     : LifeExpensesDic,
                        withPatrimoine patrimoine : Patrimoin,
                        withKPIs kpis             : inout KpiDictionary,
                        withMode simulationMode   : SimulationModeEnum,
                        using model               : Model) -> KpiResultsDictionary {
        // création du calculateur de KPIs
        var kpiComputer = KpiComputer(simulationMode : simulationMode,
                                      model          : model,
                                      family         : family)
        
        //-------------------------------------------------------------------------------------------
        firstYear = Date.now.year
        lastYear  = firstYear + nbOfYears - 1
        cashFlowArray.reserveCapacity(nbOfYears)
        balanceArray.reserveCapacity(nbOfYears)
        
        for year in firstYear ... lastYear {
            // construire la ligne annuelle de Cash Flow
            //------------------------------------------
            /// gérer le report de revenu imposable
            var lastYearDelayedTaxableIrppRevenue: Double
            if let lastLine = cashFlowArray.last { // de l'année précédente, s'il y en a une
                lastYearDelayedTaxableIrppRevenue = lastLine.taxableIrppRevenueDelayedToNextYear.value(atEndOf: year - 1)
            } else {
                lastYearDelayedTaxableIrppRevenue = 0
            }
            
            /// ajouter une nouvelle ligne pour une nouvelle année
            do {
                let newCashFlowLine = try CashFlowLine(run                                   : run,
                                                       withYear                              : year,
                                                       withFamily                            : family,
                                                       withExpenses                          : expenses,
                                                       withPatrimoine                        : patrimoine,
                                                       taxableIrppRevenueDelayedFromLastyear : lastYearDelayedTaxableIrppRevenue,
                                                       using                                 : model)
                cashFlowArray.append(newCashFlowLine)
                // ajouter les éventuelles successions survenues pendant l'année à la liste globale
                legalSuccessions   += newCashFlowLine.legalSuccessions
                // ajouter les éventuelles transmissions d'assurance vie survenues pendant l'année à la liste globale
                lifeInsSuccessions += newCashFlowLine.lifeInsSuccessions
            } catch {
                /// il n'y a plus de Cash => on arrête la simulation
                lastYear = year
                // on calcule les KPI sur la base du dernier bilan connu (fin de l'année précédente)
                kpiComputer.computeKpisAtZeroCashAvailable(year                 : year,
                                                           withKPIs             : &kpis,
                                                           withBalanceSheetLine : balanceArray.last)
                SimulationLogger.shared.log(run      : run,
                                            logTopic : LogTopic.simulationEvent,
                                            message  : "Fin du run: à cours de cash en \(year)")
                return kpiComputer.currentRunKpiResults // arrêter la construction de la table
            }
            
            // construire la ligne annuelle de Bilan de fin d'année
            //-----------------------------------------------------
            let newBalanceSheetLine = BalanceSheetLine(year            : year,
                                                       withMembersName : family.membersName,
                                                       withAdultsName  : family.adultsName,
                                                       withAssets      : patrimoine.assets.allOwnableItems,
                                                       withLiabilities : patrimoine.liabilities.allOwnableItems)
            
            if family.nbOfAdultAlive(atEndOf: year) < family.nbOfAdultAlive(atEndOf: year-1) {
                // décès d'un adulte en cours d'année
                // gérer les KPI n°1, 2, 3 au décès de l'un ou des 2 conjoints
                // attention: à ce stade les transmissions de succession ont déjà été réalisées
                kpiComputer.computeKpisAtDeath(year                               : year,
                                               withKPIs                           : &kpis,
                                               withBalanceArray                   : balanceArray,
                                               balanceSheetLineAfterTransmission  : newBalanceSheetLine)
            }
            
            balanceArray.append(newBalanceSheetLine)
            
            if family.nbOfAdultAlive(atEndOf: year) == 0 {
                // il n'y a plus d'adulte vivant à la fin de l'année
                // on arrête la simulation après avoir clos les dernières successions
                lastYear = year
                SimulationLogger.shared.log(run      : run,
                                            logTopic : LogTopic.simulationEvent,
                                            message  : "Fin du run: plus d'adulte en vie en \(year)")
                return kpiComputer.currentRunKpiResults // arrêter la construction de la table
            }
        }
        
        /// KPI n°3 : on est arrivé à la fin de la simulation
        // rechercher le minimum d'actif financier net au cours du temps
        kpiComputer.computeMinimumAssetKpiValue(withKPIs             : &kpis,
                                                withBalanceArray     : balanceArray)
        SimulationLogger.shared.log(run      : run,
                                    logTopic : LogTopic.simulationEvent,
                                    message  : "Fin du run: date de fin de run atteinte en \(lastYear)")
        return kpiComputer.currentRunKpiResults
    }
}
