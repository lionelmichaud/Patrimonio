//
//  LoadTestFiles.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/12/2021.
//

import Foundation
import ModelEnvironment
import PersonModel
import FamilyModel
import PatrimoineModel
import LifeExpense
import Persistence
import DateBoundary

struct TestEnvir {
    static var dataStore  : Store!
    static var model      : Model!
    static var family     : Family!
    static var expenses   : LifeExpensesDic!
    static var patrimoine : Patrimoin!
    static var simulation : Simulation!
    static var uiState    : UIState!

    static func loadTestFilesFromTemplate() {
        do {
            let folder = try PersistenceManager.importTemplatesFromAppAndCheckCompatibility()
            dataStore  = Store()
            uiState    = UIState()
            family     = Family()

            // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
            DateBoundary.setPersonEventYearProvider(family)
            // injection de family dans la propriété statique de Expense
            LifeExpense.setMembersCountProvider(family)
            // injection de family dans la propriété statique de Adult
            Adult.setAdultRelativesProvider(family)
            // injection de family dans la propriété statique de Patrimoin
            Patrimoin.familyProvider = family

            model      = try Model(fromFolder: folder)
            patrimoine = try Patrimoin(fromFolder : folder)

            try family = Family(fromFolder    : folder,
                                    using         : model)
            try expenses = LifeExpensesDic(fromFolder: folder)
            simulation = try Simulation(fromFolder: folder)

            /// gérer les dépendances entre le Modèle et les objets applicatifs
            DependencyInjector.updateDependencies(to: model)

            /// rendre le Dossier actif seulement si tout c'est bien passé
            dataStore.activate(dossierAtIndex: 0)

            /// remettre à zéro la simulation et sa vue
            simulation.notifyComputationInputsModification()
        } catch {
            print("Echec de l'initialisation des fichiers de test à partir du Bundle Application")
        }
    }

    static func loadTestFilesFromBundle() {
        dataStore  = Store()
        uiState    = UIState()
        family     = Family()

        // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
        DateBoundary.setPersonEventYearProvider(family)
        // injection de family dans la propriété statique de Expense
        LifeExpense.setMembersCountProvider(family)
        // injection de family dans la propriété statique de Adult
        Adult.setAdultRelativesProvider(family)
        // injection de family dans la propriété statique de Patrimoin
        Patrimoin.familyProvider = family

        model      = Model(fromBundle     : Bundle.main)
        patrimoine = Patrimoin(fromBundle : Bundle.main)
        do {
            try family = Family(fromBundle    : Bundle.main,
                                    using         : model)
            try expenses = LifeExpensesDic(fromBundle: Bundle.main)
        } catch {
            print("Echec de l'initialisation des fichiers de test à partir du Bundle Application")
        }
        simulation = Simulation(fromBundle: Bundle.main)

        /// gérer les dépendances entre le Modèle et les objets applicatifs
        DependencyInjector.updateDependencies(to: model)

        /// rendre le Dossier actif seulement si tout c'est bien passé
        dataStore.activate(dossierAtIndex: 0)

        /// remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()
    }
}
