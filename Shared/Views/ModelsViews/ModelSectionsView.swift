//
//  ScenarioListView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ModelSectionsView: View {
    @EnvironmentObject var uiState                 : UIState
    @State private var isModelDeterminiticExpanded : Bool = false
    @State private var isModelStatisticExpanded    : Bool = false
    
    var body: some View {
        Section(header: Text("Modèles Déterministe")) {
            NavigationLink(destination: ModelDeterministicView(),
                           tag         : .deterministicModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Tous les Modèles")
            }
            .isDetailLink(true)
        }
        Section(header: Text("Modèles Statistiques")) {
            NavigationLink(destination: ModelHumanView(),
                           tag         : .humanModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Modèle Humain")
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelEconomyView(),
                           tag         : .economyModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Modèle Economique")
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelSociologyView(),
                           tag         : .sociologyModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Modèle Sociologique")
            }
            .isDetailLink(true)
        }
        Section(header: Text("Assistants")) {
            // Vue assistant statistiques
            NavigationLink(destination : StatisticsChartsView(),
                           tag         : .statisticsAssistant,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Assistant Distributions")
            }
            .isDetailLink(true)
        }
    }
}

struct ScenarioModelListView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        Form {
            ModelSectionsView()
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
                .previewLayout(.sizeThatFits)
        }        
    }
}
