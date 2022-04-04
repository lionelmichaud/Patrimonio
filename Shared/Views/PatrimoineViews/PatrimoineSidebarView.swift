//
//  PatrimoineSidebarView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Persistence
import PatrimoineModel
import FamilyModel
import HelpersView
import SimulationAndVisitors

struct PatrimoineSidebarView: View {
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var dataStore  : Store
    let simulationReseter: CanResetSimulationP
    @State private var alertItem: AlertItem?
    
    var body: some View {
        NavigationView {
            /// Primary view
            Group {
                if dataStore.activeDossier != nil {
                    Button("Réinitialiser à partir du dossier",
                           action: reinitialize)
                    .disabled(dataStore.activeDossier == nil || dataStore.activeDossier!.folder == nil)
                    .buttonStyle(.bordered)
                }

                List {
                    // entête
                    PatrimoineHeaderView()

                    if dataStore.activeDossier != nil {
                        // Bilan net = Actif - Passif
                        PatrimoineTotalView()

                        // actifs
                        AssetSidebarView(simulationReseter: simulationReseter)

                        // passifs
                        LiabilitySidebarView(simulationReseter: simulationReseter)

                    }
                }
                .listStyle(.sidebar)
                .navigationViewStyle(.columns)
                .navigationTitle("Patrimoine")
            }

            /// vue par défaut
            PatrimoineSummaryView()
        }
        .environment(\.horizontalSizeClass, .regular)
        .toolbar {
            EditButton()
        }
    }
    
    private func reinitialize() {
        do {
            try self.patrimoine.loadFromJSON(fromFolder: dataStore.activeDossier!.folder!)
            uiState.patrimoineViewState.evalDate = CalendarCst.thisYear.double()
        } catch {
            self.alertItem = AlertItem(title         : Text("Le chargement a échoué"),
                                       dismissButton : .default(Text("OK")))
            
        }
    }
}

struct PatrimoineTotalView: View {
    @EnvironmentObject private var patrimoine : Patrimoin

    var body: some View {
        LabeledValueRowView(label       : "Actif Net",
                             value       : patrimoine.value(atEndOf: CalendarCst.thisYear),
                             indentLevel : 0,
                             header      : true,
                             iconItem    : nil)
        .padding([.top, .bottom])
    }
}

struct PatrimoineHeaderView: View {
    var body: some View {
        NavigationLink(destination: PatrimoineSummaryView()) {
            Label(title: { Text("Synthèse") },
                  icon : { Image(systemName: "eurosign.circle.fill").imageScale(.large) })
            .font(.title3)
        }.isDetailLink(true)
    }
}

struct PatrimoineSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return TabView {
            PatrimoineSidebarView(simulationReseter: TestEnvir.simulation)
                .tabItem { Label("Patrimoine", systemImage: "dollarsign.circle.fill") }
                .tag(UIState.Tab.asset)
                .environmentObject(TestEnvir.dataStore)
                .environmentObject(TestEnvir.family)
                .environmentObject(TestEnvir.expenses)
                .environmentObject(TestEnvir.patrimoine)
                .environmentObject(TestEnvir.uiState)
        }
    }
}
