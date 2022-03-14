//
//  SimulationUserSettings.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI
import Ownership
import Persistence
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct SimulationUserSettingsView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    // si la variable d'état est locale (@State) cela ne fonctionne pas correctement
    @Preference(\.simulateVolatility) var simulateVolatility

    var body: some View {
        Form {
            Section(header: Text("Modèle Macro-Économique".uppercased()),
                    footer: Text("En mode Monté-Carlo seulement: simuler la volatilité du cours des actions et des obligations")) {
                Toggle("Simuler la volatilité des marchés financiers (actions et obligations)",
                       isOn: $simulateVolatility)
                    .onChange(of     : simulateVolatility,
                              perform: { _ in
                                // remettre à zéro la simulation et sa vue
                                simulation.notifyComputationInputsModification()
                                uiState.resetSimulationView()
                              })
            }
        }
        .navigationTitle(Text("Simulation"))
    }
}

struct SimulationUserSettings_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var simulation = Simulation()
    static var previews: some View {
        SimulationUserSettingsView()
            .environmentObject(uiState)
            .environmentObject(simulation)
    }
}
