//
//  ModelDeterministicRetirementView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI

// MARK: - Deterministic Retirement View

struct ModelDeterministicRetirementView: View {
    @ObservedObject var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Retraite").font(.headline)) {
            NavigationLink(destination: ModelRetirementGeneralView(viewModel: viewModel)) {
                Text("Pension du Régime Général")
            }
            
            NavigationLink(destination: ModelRetirementAgircView(viewModel: viewModel)) {
                Text("Pension du Régime Complémentaire")
            }

            NavigationLink(destination: ModelRetirementReversionView(viewModel: viewModel)) {
                Text("Pension de Réversion")
            }
        }
    }
}

struct ModelDeterministicRetirementView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return Form {
            ModelDeterministicRetirementView(viewModel: DeterministicViewModel(using: modelTest))
                .environmentObject(modelTest)
                .environmentObject(familyTest)
                .environmentObject(simulationTest)
        }
    }
}
