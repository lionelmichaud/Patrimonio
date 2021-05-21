//
//  SettingsView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI

struct SettingsView: View {
    @State private var ownership        = UserSettings.shared.ownershipSelection
    @State private var evaluationMethod = UserSettings.shared.assetEvaluationMethod
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: AppVersionView()) {
                    Label("À propos ...", systemImage: "info.circle")
                }
                    .isDetailLink(true)
                
                NavigationLink(destination: SimulationUserSettings()) {
                    Label("Simulation", systemImage: "function")
                }
                    .isDetailLink(true)

                NavigationLink(destination: GraphicUserSettings(ownership        : $ownership,
                                                                evaluationMethod : $evaluationMethod)) {
                    Label("Graphiques", systemImage: "chart.bar.xaxis")
                }
                    .isDetailLink(true)
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Préférences")
            
            // default View
            AppVersionView()
                .padding()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
