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

var dataStoreTest  : Store!
var modelTest      : Model!
var familyTest     : Family!
var expensesTest   : LifeExpensesDic!
var patrimoineTest : Patrimoin!
var simulationTest : Simulation!
var uiStateTest    : UIState!

func loadTestFilesFromTemplate() {
    do {
        let folder = try PersistenceManager.importTemplatesFromAppAndCheckCompatibility()
        dataStoreTest  = Store()
        uiStateTest    = UIState()
        familyTest     = Family()

        // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
        DateBoundary.setPersonEventYearProvider(familyTest)
        // injection de family dans la propriété statique de Expense
        LifeExpense.setMembersCountProvider(familyTest)
        // injection de family dans la propriété statique de Adult
        Adult.setAdultRelativesProvider(familyTest)
        // injection de family dans la propriété statique de Patrimoin
        Patrimoin.familyProvider = familyTest

        modelTest      = try Model(fromFolder: folder)
        patrimoineTest = try Patrimoin(fromFolder : folder)

        try familyTest = Family(fromFolder    : folder,
                                using         : modelTest)
        try expensesTest = LifeExpensesDic(fromFolder: folder)
        simulationTest = try Simulation(fromFolder: folder)

        /// gérer les dépendances entre le Modèle et les objets applicatifs
        DependencyInjector.manageDependencies(to: modelTest)

        /// rendre le Dossier actif seulement si tout c'est bien passé
        dataStoreTest.activate(dossierAtIndex: 0)

        /// remettre à zéro la simulation et sa vue
        simulationTest.notifyComputationInputsModification()
    } catch {
        print("Echec de l'initialisation des fichiers de test à partir du Bundle Application")
    }
}

func loadTestFilesFromBundle() {
    dataStoreTest  = Store()
    uiStateTest    = UIState()
    familyTest     = Family()
    
    // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
    DateBoundary.setPersonEventYearProvider(familyTest)
    // injection de family dans la propriété statique de Expense
    LifeExpense.setMembersCountProvider(familyTest)
    // injection de family dans la propriété statique de Adult
    Adult.setAdultRelativesProvider(familyTest)
    // injection de family dans la propriété statique de Patrimoin
    Patrimoin.familyProvider = familyTest
    
    modelTest      = Model(fromBundle     : Bundle.main)
    patrimoineTest = Patrimoin(fromBundle : Bundle.main)
    do {
        try familyTest = Family(fromBundle    : Bundle.main,
                                using         : modelTest)
        try expensesTest = LifeExpensesDic(fromBundle: Bundle.main)
    } catch {
        print("Echec de l'initialisation des fichiers de test à partir du Bundle Application")
    }
    simulationTest = Simulation(fromBundle: Bundle.main)

    /// gérer les dépendances entre le Modèle et les objets applicatifs
    DependencyInjector.manageDependencies(to: modelTest)
    
    /// rendre le Dossier actif seulement si tout c'est bien passé
    dataStoreTest.activate(dossierAtIndex: 0)
    
    /// remettre à zéro la simulation et sa vue
    simulationTest.notifyComputationInputsModification()
    uiStateTest.resetSimulationView()
}
