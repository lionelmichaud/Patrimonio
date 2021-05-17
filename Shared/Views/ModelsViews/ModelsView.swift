//
//  ScenarioView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ModelsView: View {
    @EnvironmentObject var uiState: UIState
    
    enum PushedItem {
        case summary, deterministicModel, humanModel, economyModel, sociologyModel, statisticsAssistant
    }
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // entête
                ModelsHeaderView()
                
                // liste des items de la side bar
                ModelSectionsView()
            }
            //.defaultSideBarListStyle()
            .listStyle(SidebarListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Modèles")
            
            /// vue par défaut
            ScenarioSummaryView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ModelsHeaderView: View {
    @EnvironmentObject var uiState: UIState
    
    var body: some View {
        NavigationLink(destination : ScenarioSummaryView(),
                       tag         : .summary,
                       selection   : $uiState.scenarioViewState.selectedItem) {
            Text("Dernières Valeurs Utilisées")
        }
        .isDetailLink(true)
    }
}

struct ModelsView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        ModelsView()
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
