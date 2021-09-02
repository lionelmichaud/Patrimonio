//
//  PatrimonioApp.swift
//  Shared
//
//  Created by Lionel MICHAUD on 18/04/2021.
//

import SwiftUI
import ModelEnvironment
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel

@main
struct AppMain: App {

    // MARK: - Properties

    /// data model object that you want to use throughout your app and that will be shared among the scenes
    // initializer family avant les autres car il injecte sa propre @
    // dans une propriété statique des autres Classes pendant son initialisation
    @StateObject private var dataStore  = Store()
    @StateObject private var model      = Model()
    @StateObject private var family     = Family()
    @StateObject private var expenses   = LifeExpensesDic()
    @StateObject private var patrimoine = Patrimoin()
    @StateObject private var simulation = Simulation()

    var body: some Scene {
        MainScene(dataStore  : dataStore,
                  model      : model,
                  family     : family,
                  expenses   : expenses,
                  patrimoine : patrimoine,
                  simulation : simulation)
        .commands { AppCommands() }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }

    init() {
        /// Coordonne les diffférentes entités du modèle en terme de dépendance
//        _ = Coordinator.shared
    }
}
