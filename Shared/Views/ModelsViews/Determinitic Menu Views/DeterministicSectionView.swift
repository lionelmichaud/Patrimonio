//
//  DeterministicSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/06/2021.
//

import SwiftUI

struct DeterministicSectionView: View {
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        Section(header: Text("Modèles Déterministe")) {
            NavigationLink(destination: ModelDeterministicView(),
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
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        DeterministicSectionView()
            .environmentObject(dataStore)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
