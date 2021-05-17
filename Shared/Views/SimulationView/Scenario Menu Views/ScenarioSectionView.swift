//
//  ScenarioSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 17/05/2021.
//

import SwiftUI

struct ScenarioSectionView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    var body: some View {
        if simulation.isComputed {
            Section(header: Text("Scénario") ) {
                NavigationLink(destination : ScenarioSummaryView(),
                               tag         : .lastScenarioUsed,
                               selection   : $uiState.simulationViewState.selectedItem) {
                    Text("Dernier Scénario Exécuté")
                }
                .isDetailLink(true)
            }
        }
    }
}

struct ScenarioSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ScenarioSectionView()
    }
}
