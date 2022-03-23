//
//  ContentView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Persistence
import SimulationAndVisitors
import HelpersView

struct ContentView: View {
    
    // MARK: - Environment Properties

    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var simulation : Simulation
    @SceneStorage("selectedTab") var selection = UIState.Tab.dossier
    @State private var alertItem: AlertItem?

    // MARK: - Properties

    var body: some View {
        TabView(selection: $selection) {
            /// gestion des dossiers
            DossiersSidebarView()
                .tabItem { Label("Dossiers", systemImage: "folder.fill.badge.person.crop") }
                .tag(UIState.Tab.dossier)

            /// composition de la famille
            FamilySidebarView()
                .tabItem { Label("Famille", systemImage: "person.2.fill") }
                .tag(UIState.Tab.family)
            
            /// dépenses de la famille
            ExpenseSidebarView(simulationReseter: simulation)
                .tabItem { Label("Dépenses", systemImage: "cart.fill") }
                .tag(UIState.Tab.expense)

            /// actifs & passifs du patrimoine de la famille
            PatrimoineSidebarView()
                .tabItem { Label("Patrimoine", systemImage: "dollarsign.circle.fill") }
                .tag(UIState.Tab.asset)

            /// scenario paramètrique de simulation
            ModelsSidebarView()
                .tabItem { Label("Modèles", systemImage: "slider.horizontal.3") }
                .tag(UIState.Tab.scenario)

            /// calcul et présentation des résultats de simulation
            SimulationSidebarView()
                .tabItem { Label("Simulation", systemImage: "function") }
                .tag(UIState.Tab.simulation)
            /// préférences
            SettingsSidebarView()
                .tabItem { Label("Préférences", systemImage: "gear") }
                .tag(UIState.Tab.userSettings)
            
        }
        .onAppear(perform: checkCompatibility)
        .alert(item: $alertItem, content: newAlert)
    }
    
    func checkCompatibility() {
        if !PersistenceManager.templateDirIsCompatibleWithAppVersion {
            self.alertItem =
            AlertItem(title         : Text("Attention").foregroundColor(.red),
                      message       : Text("Votre dossier Modèle n'est pas compatible de cette version de l'application. Voulez-vous le mettre à jour. Si vous le mettez à jour, vous perdrai les éventuelles modifications qu'il contient."),
                      primaryButton : .destructive(Text("Mettre à jour"),
                                                   action: {
                /// insert alert 1 action here
                do {
                    try PersistenceManager.forcedImportAllTemplateFilesFromApp()
                } catch {
                    DispatchQueue.main.async {
                        self.alertItem = AlertItem(title         : Text("Echec de la mise à jour"),
                                                   dismissButton : .default(Text("OK")))
                    }
                }
            }),
                      secondaryButton: .cancel())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ContentView()
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.uiState)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.simulation)
    }
}
