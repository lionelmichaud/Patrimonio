//
//  SettingsView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI
import Persistence

struct SettingsView: View {
    @State private var simulateVolatility      = UserSettings.shared.simulateVolatility
    @State private var kpiOwnership            = UserSettings.shared.ownershipGraphicSelection
    @State private var kpiEvaluationMethod     = UserSettings.shared.assetGraphicEvaluatedFraction
    
    @State private var graphicOwnership        = UserSettings.shared.ownershipGraphicSelection
    @State private var graphicEvaluationMethod = UserSettings.shared.assetGraphicEvaluatedFraction
    
    @State private var shareCsvFiles           = UserSettings.shared.shareCsvFiles
    @State private var shareImageFiles         = UserSettings.shared.shareImageFiles

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: AppVersionView()) {
                    Label("À propos ...", systemImage: "info.circle")
                }
                    .isDetailLink(true)
                
                // Simulation settings
                NavigationLink(destination: SimulationUserSettingsView(simulateVolatility: $simulateVolatility,
                                                                       ownership         : $kpiOwnership)) {
                    Label("Simulation", systemImage: "function")
                }
                    .isDetailLink(true)

                // Graphics settings
                NavigationLink(destination: GraphicUserSettingsView(ownership        : $graphicOwnership,
                                                                    evaluatedFraction: $graphicEvaluationMethod)) {
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
