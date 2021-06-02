//
//  ComputationSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/06/2021.
//

import SwiftUI

struct ComputationSectionView: View {
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

struct ComputationSectionView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        ComputationSectionView()
            .environmentObject(dataStore)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
