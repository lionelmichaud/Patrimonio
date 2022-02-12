//
//  StatisticSidebarSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/06/2021.
//

import SwiftUI
import Persistence
import ModelEnvironment
import PatrimoineModel
import FamilyModel

struct StatisticSidebarSectionView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        Section(header: Text("Modèles Statistiques")) {
            NavigationLink(destination: ModelHumanView(),
                           tag         : .statHumanModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Modèle Humain")
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelEconomyView(),
                           tag         : .statEconomyModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Modèle Economique")
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelSociologyView(),
                           tag         : .statSociologyModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Text("Modèle Sociologique")
            }
            .isDetailLink(true)
        }
    }
}

struct StatisticSectionView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return StatisticSidebarSectionView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(patrimoineTest)
            .environmentObject(simulationTest)
    }
}
