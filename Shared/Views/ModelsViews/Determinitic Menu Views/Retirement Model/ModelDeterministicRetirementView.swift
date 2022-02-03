//
//  ModelDeterministicRetirementView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI

// MARK: - Deterministic Retirement View

struct ModelDeterministicRetirementView: View {
    @EnvironmentObject private var viewModel : DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Retraite").font(.headline)) {
            NavigationLink(destination: ModelRetirementGeneralView()
                            .environmentObject(viewModel)) {
                Text("Pension du Régime Général")
                Spacer()
                VersionText(version: viewModel.retirementModel.regimeGeneral.model.version)
            }
            
            NavigationLink(destination: ModelRetirementAgircView()
                            .environmentObject(viewModel)) {
                Text("Pension du Régime Complémentaire")
                Spacer()
                VersionText(version: viewModel.retirementModel.regimeAgirc.model.version)
            }

            NavigationLink(destination: ModelRetirementReversionView()
                            .environmentObject(viewModel)) {
                Text("Pension de Réversion")
                Spacer()
                VersionText(version: viewModel.retirementModel.reversion.model.version)
            }
        }
    }
}

struct ModelDeterministicRetirementView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return Form {
            ModelDeterministicRetirementView()
                .environmentObject(modelTest)
                .environmentObject(familyTest)
                .environmentObject(simulationTest)
                .environmentObject(viewModel)
        }
        .preferredColorScheme(.dark)
    }
}
