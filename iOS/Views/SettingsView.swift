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
    @State private var shareCsvFiles    = UserSettings.shared.shareCsvFiles
    @State private var shareImageFiles  = UserSettings.shared.shareImageFiles

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: AppVersionView()) {
                    Label("À propos ...", systemImage: "info.circle")
                }
                    .isDetailLink(true)
                
                // Simulation settings
                NavigationLink(destination: SimulationUserSettingsView()) {
                    Label("Simulation", systemImage: "function")
                }
                    .isDetailLink(true)

                // Graphics settings
                NavigationLink(destination: GraphicUserSettings(ownership        : $ownership,
                                                                evaluationMethod : $evaluationMethod)) {
                    Label("Graphiques", systemImage: "chart.bar.xaxis")
                }
                    .isDetailLink(true)

                // Export settings
                NavigationLink(destination: ExportSettingsView(shareCsvFiles   : $shareCsvFiles,
                                                               shareImageFiles : $shareImageFiles)) {
                    Label("Export", systemImage: "square.and.arrow.up")
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
