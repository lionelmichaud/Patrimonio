//
//  DeterministicSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/06/2021.
//

import SwiftUI
import ModelEnvironment
import Persistence
import PatrimoineModel
import FamilyModel

struct DeterministicSidebarSectionView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        Section(header: Text("Modèles Déterministe")) {
            NavigationLink(destination: ModelDeterministicView(using: model),
                           tag         : .deterministicModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Tous les Modèles")
            }
            .isDetailLink(true)
        }
    }
}

struct DeterministicSectionView_Previews: PreviewProvider {
    
    static var previews: some View {
        loadTestFilesFromBundle()
        return DeterministicSidebarSectionView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(patrimoineTest)
            .environmentObject(simulationTest)
    }
}
