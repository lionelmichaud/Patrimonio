//
//  DeterministicSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/06/2021.
//

import SwiftUI
import ModelEnvironment
import Persistence

struct DeterministicSectionView: View {
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
    static let dataStore  = Store()
    static var model      = Model(fromBundle: Bundle.main)
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        DeterministicSectionView()
            .environmentObject(dataStore)
            .environmentObject(model)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
