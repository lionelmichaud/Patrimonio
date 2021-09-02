//
//  MainScene.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import LifeExpense
import Persistence
import PatrimoineModel

/// Defines the main scene of the App
struct MainScene: Scene {
    
    // MARK: - Environment Properties

    @Environment(\.scenePhase) var scenePhase
    
    // MARK: - Properties

    @ObservedObject var dataStore  : Store
    @ObservedObject var model      : Model
    @ObservedObject var family     : Family
    @ObservedObject var expenses   : LifeExpensesDic
    @ObservedObject var patrimoine : Patrimoin
    @ObservedObject var simulation : Simulation
    
    /// object that you want to use throughout your views and that will be specific to each scene
    @StateObject private var uiState = UIState()

    var body: some Scene {
        WindowGroup {
            /// defines the views hierachy of the scene
            ContentView()
                .environmentObject(dataStore)
                .environmentObject(model)
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(expenses)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
        }
        .onChange(of: scenePhase) { scenePhase in
            switch scenePhase {
                case .active:
                    ()
                case .background:
                    ()
                default:
                    break
            }
        }
    }
}
