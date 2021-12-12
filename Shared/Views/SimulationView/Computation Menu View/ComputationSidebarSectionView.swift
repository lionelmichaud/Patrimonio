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

struct ComputationSidebarSectionView: View {
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
            // calcul de simulation
            NavigationLink(destination : ComputationView(),
                           tag         : .computationView,
                           selection   : $uiState.simulationViewState.selectedItem) {
                Text("Calculs")
            }
            .isDetailLink(true)
    }
}

struct ComputationSidebarSectionView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ComputationSidebarSectionView()
            .environmentObject(modelTest)
            .environmentObject(uiStateTest)
            .environmentObject(dataStoreTest)
            .environmentObject(familyTest)
            .environmentObject(patrimoineTest)
            .environmentObject(simulationTest)
    }
}
