//
//  ComputationSideBarSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/06/2021.
//

import SwiftUI
import Persistence
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct ComputationSidebarSectionView: View {
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
            // calcul de simulation
            NavigationLink(destination : ComputationView(),
                           tag         : .computationView,
                           selection   : $uiState.simulationViewState.selectedItem) {
                Label("Calculs", systemImage: "function")
            }
            .isDetailLink(true)
    }
}

struct ComputationSidebarSectionView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ComputationSidebarSectionView()
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.uiState)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.simulation)
    }
}
