//
//  SettingsView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI

struct SettingsView: View {
    @State private var ownership        = UserSettings.shared.ownershipSelection
    @State private var evaluationMethod = UserSettings.shared.assetEvaluationMethod

    private enum Tabs: Hashable {
        case version, simulation, graphique
    }
    
    var body: some View {
        TabView {
            AppVersionView()
                .tabItem {
                    Label("Version", systemImage: "gear")
                }
                .tag(Tabs.version)
            SimulationUserSettings()
                .tabItem {
                    Label("Simulation", systemImage: "gear")
                }
                .tag(Tabs.simulation)
            GraphicUserSettings(ownership        : $ownership,
                                evaluationMethod : $evaluationMethod)
                .tabItem {
                    Label("Graphiques", systemImage: "star")
                }
                .tag(Tabs.graphique)
        }
        .padding(20)
        .frame(width: 375, height: 150)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showPreview") private var showPreview = true
    @AppStorage("fontSize") private var fontSize = 12.0
    
    var body: some View {
        Form {
            Toggle("Show Previews", isOn: $showPreview)
            Slider(value: $fontSize, in: 9...96) {
                Text("Font Size (\(fontSize, specifier: "%.0f") pts)")
            }
        }
        .padding(20)
        .frame(width: 350, height: 100)
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
