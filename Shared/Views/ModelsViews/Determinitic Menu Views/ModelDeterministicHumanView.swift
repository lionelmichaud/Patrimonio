//
//  ModelDeterministicHumanView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import ModelEnvironment

// MARK: - Deterministic HumanLife View

struct ModelDeterministicHumanView: View {
    @ObservedObject var viewModel: DeterministicViewModel
    
    var body: some View {
        Section(header: Text("Modèle Humain")) {
            Stepper(value : $viewModel.menLifeExpectation,
                    in    : 50 ... 100) {
                HStack {
                    Text("Espérance de vie d'un Homme")
                    Spacer()
                    Text("\(viewModel.menLifeExpectation) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.menLifeExpectation) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.womenLifeExpectation,
                    in    : 50 ... 100) {
                HStack {
                    Text("Espérance de vie d'une Femme")
                    Spacer()
                    Text("\(viewModel.womenLifeExpectation) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.womenLifeExpectation) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.nbOfYearsOfdependency,
                    in    : 0 ... 10) {
                HStack {
                    Text("Nombre d'années de dépendance")
                    Spacer()
                    Text("\(viewModel.nbOfYearsOfdependency) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.nbOfYearsOfdependency) { _ in viewModel.isModified = true }
        }
    }
}

struct ModelDeterministicHumanView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        Form {
            ModelDeterministicHumanView(viewModel: DeterministicViewModel(using: model))
        }
    }
}
