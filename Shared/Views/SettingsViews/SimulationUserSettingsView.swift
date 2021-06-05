//
//  SimulationUserSettings.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI

struct SimulationUserSettingsView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var simulateVolatility = UserSettings.shared.simulateVolatility

    var body: some View {
        Form {
            Section(footer: Text("En mode Monté-Carlo seulement: simuler la volatilité du cours des actions et des obligations")) {
                Toggle("Simuler la volatilité des marchés financiers (actions et obligations)",
                       isOn: $simulateVolatility)
                    .onChange(of     : simulateVolatility,
                              perform: { _ in
                                // remettre à zéro la simulation et sa vue
                                simulation.reset()
                                uiState.reset()
                              })
            }
        }
    }
}

struct SimulationUserSettings_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    static var previews: some View {
        SimulationUserSettingsView()
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
