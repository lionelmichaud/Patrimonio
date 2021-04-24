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
                NavigationLink("A propos",
                               destination: AppVersionView())
                    .isDetailLink(true)
                
                NavigationLink("Simulation",
                               destination: SimulationUserSettings())
                    .isDetailLink(true)

                NavigationLink("Graphiques",
                               destination: GraphicUserSettings(ownership        : $ownership,
                                                                evaluationMethod : $evaluationMethod))
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
