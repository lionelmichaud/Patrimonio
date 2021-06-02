//
//  ScenarioView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ModelsView: View {
    @EnvironmentObject private var uiState: UIState
    
    enum PushedItem {
        case deterministicModel, humanModel, economyModel, sociologyModel, statisticsAssistant
    }
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // Modèle Déterministique
                DeterministicSectionView()
                
                // Modèle Statistique
                StatisticSectionView()
                
                // Assistant modèle statistique
                RandomizerAssistantSectionView()
            }
            //.defaultSideBarListStyle()
            .listStyle(SidebarListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Modèles")
            
            /// vue par défaut
            ModelDeterministicView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ModelsView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        ModelsView()
            .environmentObject(dataStore)
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
