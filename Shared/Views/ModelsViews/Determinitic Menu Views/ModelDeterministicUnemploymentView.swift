//
//  ModelDeterministicUnemploymentView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation

struct ModelDeterministicUnemploymentView: View {
    @EnvironmentObject private var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: headerWithVersion(label: "Modèle Chômage",
                                          version: viewModel.unemploymentModel.allocationChomage.model.version)) {
            NavigationLink(destination:
                            UnemploymentAreDurationGridView(label: "Barême de durée d'indemnisation",
                                                            grid: $viewModel.unemploymentModel.allocationChomage.model.durationGrid)
                            .environmentObject(viewModel)) {
                Text("Durée d'indemnisation")
            }.isDetailLink(true)

            NavigationLink(destination: ModelUnemploymentAmountView()
                            .environmentObject(viewModel)) {
                Text("Différés d'indemnisation")
            }

            NavigationLink(destination: ModelUnemploymentDiffereView()
                            .environmentObject(viewModel)) {
                Text("Allocation de Recherche d'Emploi (ARE)")
            }
        }
    }
}

//struct ModelDeterministicUnemploymentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ModelDeterministicUnemploymentView()
//    }
//}
