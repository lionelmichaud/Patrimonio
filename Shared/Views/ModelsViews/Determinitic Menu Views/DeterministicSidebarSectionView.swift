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
import SimulationAndVisitors
import FamilyModel

struct DeterministicSidebarSectionView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        Section(header: Text("Modèles Déterministe")) {
            // modèle vie humaine
            NavigationLink(destination: ModelDeterministicHumanView(),
                           tag         : .detHumanModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Humain", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)
            
            // modèle économie
            NavigationLink(destination: ModelDeterministicEconomyView(),
                           tag         : .detEconomyModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Economique", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)
            
            // modèle sociologie
            NavigationLink(destination: ModelDeterministicSociologyView(),
                           tag         : .detSociologyModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Sociologique", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)
            
            // modèle sociologie
            NavigationLink(destination: ModelDeterministicRetirementView(),
                           tag         : .detRetirementModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Retraite", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)
            
            // modèle sociologie
            NavigationLink(destination: ModelDeterministicFiscalView(),
                           tag         : .detFiscalModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Fiscal", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)
            
            // modèle sociologie
            NavigationLink(destination: ModelDeterministicUnemploymentView(),
                           tag         : .detUnemploymentModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Chômage", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)

       }
    }
}

struct DeterministicSectionView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return
            NavigationView {
                DeterministicSidebarSectionView()
                    .environmentObject(TestEnvir.model)
                    .environmentObject(TestEnvir.uiState)
                    .environmentObject(TestEnvir.simulation)
                EmptyView()
            }
    }
}
