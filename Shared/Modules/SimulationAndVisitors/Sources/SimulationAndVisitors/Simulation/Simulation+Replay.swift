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
import SocialAccounts
import SimulationLogger
import Persistence

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Simulation")

extension Simulation {
    /// Rejouer un run
    ///
    /// [- Sauvegarder l'état du patrimoine avant de lancer les calculs (et donc de modifier l'état du patrimoine] Pourquoi pas fait ?
    ///
    /// - Restaurer l'état du patrimoine à la fin des calculs
    ///
    /// - Parameters:
    ///   - thisRun: paramètres du run à rejouer
    ///
    public func replay(thisRun                   : SimulationResultLine,
                       withFamily family         : Family,
                       withExpenses expenses     : LifeExpensesDic,
                       withPatrimoine patrimoine : Patrimoin,
                       using model               : Model) {
        defer {
            // jouer le son à la fin de la simulation
            Simulation.playSound()
        }
        
        guard let nbOfYears = lastYear - firstYear + 1 else {
            fatalError()
        }
        
        process(event: .onComputationTrigger)
        
        // sauvegarder l'état initial du patrimoine pour y revenir à la fin de chaque run
        //patrimoine.saveState()
        
        // propriétés indépendantes du nombre de run
        firstYear = CalendarCst.thisYear
        lastYear  = firstYear + nbOfYears - 1
        
        currentRunNb = 1
        SimulationLogger.shared.reset()
        SimulationLogger.shared.log(run      : currentRunNb,
                                    logTopic : LogTopic.simulationEvent,
                                    message  : "Début : \(firstYear!)")
        
        // fixer tous les paramètres du run à rejouer
        try! model.economyModel.setRandomValue(to                 : thisRun.dicoOfEconomyRandomVariables,
                                               simulateVolatility : Preferences.standard.simulateVolatility,
                                               firstYear          : firstYear!,
                                               lastYear           : lastYear!)
        model.socioEconomyModel.setRandomValue(to: thisRun.dicoOfSocioEconomyRandomVariables)
        family.adults.forEach { adult in
            adult.ageOfDeath           = thisRun.dicoOfAdultsRandomProperties[adult.displayName]!.ageOfDeath
            adult.nbOfYearOfDependency = thisRun.dicoOfAdultsRandomProperties[adult.displayName]!.nbOfYearOfDependency
        }
        
        // Réinitialiser les comptes sociaux
        socialAccounts = SocialAccounts()
        
        // construire les comptes sociaux du patrimoine de la famille
        _ = socialAccounts.build(run            : currentRunNb,
                                 nbOfYears      : nbOfYears,
                                 withFamily     : family,
                                 withExpenses   : expenses,
                                 withPatrimoine : patrimoine,
                                 withKPIs       : &kpis,
                                 withMode       : mode,
                                 using          : model)
        
        // restaurer l'état à la dernière valeur sauvegardée
        patrimoine.restoreState()
        
        process(event: .onComputationCompletion)
    }

}
