//
//  ContentView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - Environment Properties

    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var simulation : Simulation
    @SceneStorage("selectedTab") var selection = UIState.Tab.dossier

    // MARK: - Properties

    var body: some View {
        TabView(selection: $uiState.selectedTab) {
            /// gestion des dossiers
            DossiersView()
                .tabItem { Label("Dossiers", systemImage: "folder.fill.badge.person.crop") }
                .tag(UIState.Tab.dossier)

            /// composition de la famille
            FamilyView()
                .tabItem { Label("Famille", systemImage: "person.2.fill") }
                .tag(UIState.Tab.family)
            
            /// dépenses de la famille
            ExpenseView(simulationReseter: simulation)
                .tabItem { Label("Dépenses", systemImage: "cart.fill") }
                .tag(UIState.Tab.expense)

            /// actifs & passifs du patrimoine de la famille
            PatrimoineView()
                .tabItem { Label("Patrimoine", systemImage: "dollarsign.circle.fill") }
                .tag(UIState.Tab.asset)

            /// scenario paramètrique de simulation
            ModelsView()
                .tabItem { Label("Modèles", systemImage: "slider.horizontal.3") }
                .tag(UIState.Tab.scenario)

            /// calcul et présentation des résultats de simulation
            SimulationView()
                .tabItem { Label("Simulation", systemImage: "function") }
                .tag(UIState.Tab.simulation)
            /// préférences
            SettingsView()
                .tabItem { Label("Préférences", systemImage: "gear") }
                .tag(UIState.Tab.userSettings)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let uiState    = UIState()
//    static let family     = try! Family(fromFolder: try! PersistenceManager.importTemplatesFromApp())
//    static let patrimoine = try! Patrimoin(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static let simulation = Simulation()

    static var previews: some View {
        Group {
            ContentView().colorScheme(.dark)
                .environmentObject(uiState)
//                .environmentObject(family)
//                .environmentObject(patrimoine)
                .environmentObject(simulation)
//                .environment(\.locale, .init(identifier: "fr"))
            //                .previewDevice(PreviewDevice(rawValue: "iPhone X"))
            //                .previewDisplayName("iPhone X")
            //            ContentView()
            //                .environment(\.locale, .init(identifier: "fr"))
            //                .previewDevice(PreviewDevice(rawValue: "iPad Air (3rd generation)"))
            //                .previewDisplayName("iPad Air (3rd generation)")
        }
        
    }
}
