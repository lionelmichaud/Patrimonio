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

struct SimulationUserSettingsView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    // si la variable d'état est locale (@State) cela ne fonctionne pas correctement
    @Binding var simulateVolatility : Bool
    @Binding var ownership          : OwnershipNature

    var body: some View {
        Form {
            Section(header: Text("Modèle Macro-Économique".uppercased()),
                    footer: Text("En mode Monté-Carlo seulement: simuler la volatilité du cours des actions et des obligations")) {
                Toggle("Simuler la volatilité des marchés financiers (actions et obligations)",
                       isOn: $simulateVolatility)
                    .onChange(of     : simulateVolatility,
                              perform: { newValue in
                                UserSettings.shared.simulateVolatility = newValue
                                // remettre à zéro la simulation et sa vue
                                simulation.notifyComputationInputsModification()
                                uiState.resetSimulationView()
                              })
            }
            
//            Section(header: Text("Calcul des KPI".uppercased()),
//                    footer: Text("L'évolution dans le temps du bilan des parents ne prendra en compte que les biens satisfaisant à ce critère")) {
//                CasePicker(pickedCase: $ownership, label: "Filtrage des actifs et passifs des parents")
//                    .pickerStyle(DefaultPickerStyle())
//                    .onChange(of     : ownership,
//                              perform: { newValue in
//                                UserSettings.shared.ownershipKpiSelection = newValue
//                              })
//            }
            
//            Section(footer: Text("L'évolution dans le temps du bilan des parents prendra en compte cette valorisation")) {
//                CasePicker(pickedCase: $evaluationContext, label: "Valorisation d'un bien")
//                    .pickerStyle(DefaultPickerStyle())
//                    .onChange(of     : evaluationContext,
//                              perform: { newValue in
//                                UserSettings.shared.assetKpiEvaluatedFraction = newValue
//                              })
//            }
        }
    }
}

struct SimulationUserSettings_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var simulation = Simulation()
    static var previews: some View {
        SimulationUserSettingsView(simulateVolatility : .constant(true),
                                   ownership          : .constant(.all))
            .environmentObject(uiState)
            .environmentObject(simulation)
    }
}
