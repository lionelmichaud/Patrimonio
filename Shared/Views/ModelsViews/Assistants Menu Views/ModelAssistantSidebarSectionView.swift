//
//  RandomizerAssistantSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/06/2021.
//

import SwiftUI
import Persistence
import PatrimoineModel
import SimulationAndVisitors
import FamilyModel

struct ModelAssistantSidebarSectionView: View {
    @EnvironmentObject private var uiState: UIState
    
    var body: some View {
        Section {
            // Vue gestion des modèles
            NavigationLink(destination : ModelManagerView(),
                           tag         : .modelManager,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Gestion des Modèles", systemImage: "arrow.left.arrow.right")
            }.isDetailLink(true)
            
            // Vue assistant statistiques
            NavigationLink(destination : StatisticsChartsView(),
                           tag         : .statisticsAssistant,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Assistant Distributions", systemImage: "chart.xyaxis.line")
            }.isDetailLink(true)
        } header: {
            Text("Assistants")
        }
    }
}

struct RandomizerAssistantSectionView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        ModelAssistantSidebarSectionView()
            .environmentObject(dataStore)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
