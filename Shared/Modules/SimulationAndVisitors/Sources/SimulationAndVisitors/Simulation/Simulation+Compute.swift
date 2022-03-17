//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 14/03/2022.
//

import Foundation
import os
import AppFoundation
import ModelEnvironment
import FamilyModel
import LifeExpense
import PatrimoineModel
import EconomyModel
import SocioEconomyModel
import SimulationLogger
import SocialAccounts
import Persistence

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Simulation")

extension Simulation {

    /// Exécuter une simulation Déterministe ou Aléatoire
    ///
    /// - Sauvegarder l'état du patrimoine avant de lancer les claucls (et donc de modifier l'état du patrimoine
    ///
    /// - Restaurer l'état du patrimoine à la fin des calculs
    ///
    /// - Parameters:
    ///   - model: modèle à utiliser
    ///   - nbOfYears: nombre d'années à construire
    ///   - nbOfRuns: nombre de run à calculer (> 1: mode aléatoire)
    ///   - family: la famille
    ///   - expenses: les dépenses de la famille
    ///   - patrimoine: le patrimoine de la famille
    ///
    public func compute(using model               : Model,
                        nbOfYears                 : Int,
                        nbOfRuns                  : Int,
                        withFamily family         : Family,
                        withExpenses expenses     : LifeExpensesDic,
                        withPatrimoine patrimoine : Patrimoin) {
        
        defer {
            // jouer le son à la fin de la simulation
            Simulation.playSound()
        }
        
        let monteCarlo = nbOfRuns > 1
        if monteCarlo && mode != .random {
            customLog.log(level: .fault, "monteCarlo && mode != .random")
            fatalError()
        }
        
        process(event: .onComputationTrigger)
        
        //propriétés indépendantes du nombre de run
        // mettre à jour les variables d'état dans le thread principal
        //        DispatchQueue.main.async {
        firstYear = CalendarCst.thisYear
        lastYear  = firstYear + nbOfYears - 1
        //        } // Dispatcheue.main.async
        
        var dicoOfAdultsRandomProperties      = DictionaryOfAdultRandomProperties()
        var dicoOfEconomyRandomVariables      = Economy.DictionaryOfRandomVariable()
        var dicoOfSocioEconomyRandomVariables = SocioEconomy.DictionaryOfRandomVariable()
        
        if monteCarlo {
            // remettre à zéro les historiques des tirages aléatoires
            resetAllRandomHistories(using: model)
            // remettre à zéro la table de résultat
            monteCarloResultTable = SimulationResultTable()
        }
        
        // sauvegarder l'état initial du patrimoine pour y revenir à la fin de chaque run
        patrimoine.saveState()
        
        // calculer tous les runs
        for run in 1...nbOfRuns {
            //            DispatchQueue.main.async { [self] in
            currentRunNb = run
            //            } // DispatchQueue.main.async
            SimulationLogger.shared.log(run      : currentRunNb,
                                        logTopic : LogTopic.simulationEvent,
                                        message  : "Début : \(firstYear!)")
            // récupérer les propriétés aléatoires
            if monteCarlo {
                // re-générer les propriétés aléatoires à chaque run si on est en mode Aléatoire
                getNextRandomProperties(using: model,
                                        family,
                                        &dicoOfAdultsRandomProperties,
                                        &dicoOfEconomyRandomVariables,
                                        &dicoOfSocioEconomyRandomVariables)
            } else {
                // récupérer les propriétés aléatoires courantes en mode Déterministe
                getCurrentRandomProperties(using: model,
                                           family,
                                           &dicoOfAdultsRandomProperties,
                                           &dicoOfEconomyRandomVariables,
                                           &dicoOfSocioEconomyRandomVariables)
            }
            
            // Réinitialiser les comptes sociaux
            socialAccounts = SocialAccounts()
            // Remettre à zéro l'historique des KPI (Histogramme)
            // - au début d'un MontéCarlo seulement
            // - mais pas à chaque Run
            if run == 1 {
                resetKPIs()
                SimulationLogger.shared.reset()
            }
            
            // Exécuter la simulation: construire les comptes sociaux du patrimoine de la famille
            let dicoOfRunKpiResults =
                socialAccounts.build(run            : run,
                                     nbOfYears      : nbOfYears,
                                     withFamily     : family,
                                     withExpenses   : expenses,
                                     withPatrimoine : patrimoine,
                                     withKPIs       : &kpis,
                                     withMode       : mode,
                                     using          : model)
            // Synthèse du Run de Simulation
            currentRunResults =
                SimulationResultLine(runNumber                         : run,
                                     dicoOfAdultsRandomProperties      : dicoOfAdultsRandomProperties,
                                     dicoOfEconomyRandomVariables      : dicoOfEconomyRandomVariables,
                                     dicoOfSocioEconomyRandomVariables : dicoOfSocioEconomyRandomVariables,
                                     dicoOfKpiResults                  : dicoOfRunKpiResults)
            if monteCarlo {
                monteCarloResultTable.append(currentRunResults)
                
                // Dernier run, créer les histogrammes et y ranger
                // les échantillons de KPIs si on est en mode Aléatoire
                if run == nbOfRuns {
                    kpis.generateHistograms()
                }
            }
            
            // restaurer l'état à la dernière valeur sauvegardée
            patrimoine.restoreState()
        }
        
        process(event: .onComputationCompletion)
    }
    
    /// Remettre à zéro les historiques des tirages aléatoires avant le lancement d'un MontéCarlo
    private func resetAllRandomHistories(using model: Model) {
        model.humanLife.model!.resetRandomHistory()
        model.economy.model!.resetRandomHistory()
        model.socioEconomy.model!.resetRandomHistory()
    }
    
    /// Remettre à zéro l'historique des KPI (Histogramme)
    ///  - au début d'un MontéCarlo seulement
    ///  - mais pas à chaque Run
    private func resetKPIs() {
        kpis.reset(withMode: mode)
    }

    /// Récupérer les propriétés aléatoires courantes en mode Déterministe
    private func getCurrentRandomProperties(using model: Model,
                                            _ family                            : Family,
                                            _ dicoOfAdultsRandomProperties      : inout DictionaryOfAdultRandomProperties,
                                            _ dicoOfEconomyRandomVariables      : inout Economy.DictionaryOfRandomVariable,
                                            _ dicoOfSocioEconomyRandomVariables : inout SocioEconomy.DictionaryOfRandomVariable) {
        dicoOfAdultsRandomProperties      = family.currentRandomProperties()
        dicoOfEconomyRandomVariables      = model.economyModel.currentRandomizersValues(withMode: mode)
        dicoOfSocioEconomyRandomVariables = model.socioEconomyModel.currentRandomizersValues(withMode: mode)
    }
    
    /// Re-générer les propriétés aléatoires à chaque run si on est en mode Aléatoire
    private func getNextRandomProperties(using model                         : Model,
                                         _ family                            : Family,
                                         _ dicoOfAdultsRandomProperties      : inout DictionaryOfAdultRandomProperties,
                                         _ dicoOfEconomyRandomVariables      : inout Economy.DictionaryOfRandomVariable,
                                         _ dicoOfSocioEconomyRandomVariables : inout SocioEconomy.DictionaryOfRandomVariable) {
        // re-générer les propriétés aléatoires de la famille
        dicoOfAdultsRandomProperties = family.nextRun(using: model)
        
        // re-générer les propriétés aléatoires du modèle macro économique
        dicoOfEconomyRandomVariables = try! model.economyModel.nextRun(simulateVolatility : Preferences.standard.simulateVolatility,
                                                                       firstYear          : firstYear!,
                                                                       lastYear           : lastYear!)
        // re-générer les propriétés aléatoires du modèle socio économique
        dicoOfSocioEconomyRandomVariables = model.socioEconomyModel.nextRun()
    }
}
