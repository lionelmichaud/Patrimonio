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
import SimulationAndVisitors

struct StatisticSidebarSectionView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        Section(header: Text("Modèles Statistiques")) {
            NavigationLink(destination: ModelStatisticHumanView(),
                           tag         : .statHumanModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Humain", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelStatisticEconomyView(),
                           tag         : .statEconomyModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Economique", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)
            
            NavigationLink(destination: ModelStatisticSociologyView(),
                           tag         : .statSociologyModel,
                           selection   : $uiState.modelsViewState.selectedItem) {
                Label("Modèle Sociologique", systemImage: "slider.horizontal.3")
            }
            .isDetailLink(true)
        }
    }
}

struct StatisticSectionView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return StatisticSidebarSectionView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.simulation)
    }
}
