//
//  SettingsView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI

struct SettingsSidebarView: View {
    private enum Tabs: Hashable {
        case version, simulation, graphique
    }
    
    var body: some View {
        TabView {
            AppVersionView()
                .tabItem {
                    Label("Version", systemImage: "info.circle")
                }
                .tag(Tabs.version)
            SimulationUserSettingsView()
                .tabItem {
                    Label("Simulation", systemImage: "function")
                }
                .tag(Tabs.simulation)
            GraphicUserSettingsView()
                .tabItem {
                    Label("Graphiques", systemImage: "chart.bar.xaxis")
                }
                .tag(Tabs.graphique)
        }
        .padding(30)
        .frame(width: 600, height: 300)
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
        SettingsSidebarView()
    }
}
