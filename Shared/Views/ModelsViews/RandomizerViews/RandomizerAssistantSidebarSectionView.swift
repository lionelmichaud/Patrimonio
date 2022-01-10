//
//  RandomizerAssistantSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/06/2021.
//

import SwiftUI
import Persistence
import PatrimoineModel
import FamilyModel

struct RandomizerAssistantSidebarSectionView: View {
    @EnvironmentObject private var uiState: UIState
    
    var body: some View {
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

struct RandomizerAssistantSectionView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        RandomizerAssistantSidebarSectionView()
            .environmentObject(dataStore)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}