//
//  PatrimonioApp.swift
//  Shared
//
//  Created by Lionel MICHAUD on 18/04/2021.
//

import SwiftUI

// TODO: - décommenter les lignes
@main
struct AppMain: App {

    // MARK: - Properties

    /// data model object that you want to use throughout your app and that will be shared among the scenes
    // initializer family avant les autres car il injecte sa propre @
    // dans une propriété statique des autres Classes pendant son initialisation
    @StateObject private var family     = Family()
    @StateObject private var patrimoine = Patrimoin()
    @StateObject private var simulation = Simulation()

    var body: some Scene {
        MainScene(family     : family,
                  patrimoine : patrimoine,
                  simulation : simulation)
        .commands { AppCommands() }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
