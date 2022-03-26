//
//  ScenarioSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 17/05/2021.
//

import SwiftUI
import Statistics
import ModelEnvironment
import FamilyModel

struct ScenarioSidebarSectionView: View {
    var simulationMode       : SimulationModeEnum
    var simulationIsComputed : Bool
    @EnvironmentObject var uiState: UIState

    var body: some View {
        if simulationIsComputed {
            Section(header: Text("Scénario") ) {
                NavigationLink(destination : ScenarioSummaryView(simulationMode: simulationMode),
                               tag         : .lastScenarioUsed,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Label("Dernier Scénario Exécuté", systemImage: "film")
                }
                .isDetailLink(true)
            }
        }
    }
}

struct ScenarioSidebarSectionView_Previews: PreviewProvider {
    static let uiState = UIState()
    static var previews: some View {
        Form {
            ScenarioSidebarSectionView(simulationMode       : .deterministic,
                                       simulationIsComputed : true)
        }
            .environmentObject(uiState)
    }
}
