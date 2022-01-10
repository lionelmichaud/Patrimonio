//
//  SettingsView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI
import Persistence

struct SettingsSidebarView: View {
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
                NavigationLink(destination: GraphicUserSettingsView()) {
                    Label("Graphiques", systemImage: "chart.bar.xaxis")
                }
                .isDetailLink(true)
                
                // Export settings
                NavigationLink(destination: ExportSettingsView()) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .isDetailLink(true)
                
                // Mise à jour settings
                NavigationLink(destination: UpdateSettingsView()) {
                    Label("Mise à jour", systemImage: "square.and.arrow.down")
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
        TabView {
            SettingsSidebarView()
                .tabItem { Label("Préférences", systemImage: "gear") }
                .tag(UIState.Tab.userSettings)
        }
    }
}