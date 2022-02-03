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
    @EnvironmentObject private var viewModel : DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Humain").font(.headline)) {
            Stepper(value : $viewModel.humanLifeModel.menLifeExpectation.defaultValue,
                    in    : 50 ... 100) {
                HStack {
                    Text("Espérance de vie d'un Homme")
                    Spacer()
                    Text("\(Int(viewModel.humanLifeModel.menLifeExpectation.defaultValue)) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.humanLifeModel.menLifeExpectation.defaultValue) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.humanLifeModel.womenLifeExpectation.defaultValue,
                    in    : 50 ... 100) {
                HStack {
                    Text("Espérance de vie d'une Femme")
                    Spacer()
                    Text("\(Int(viewModel.humanLifeModel.womenLifeExpectation.defaultValue)) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.humanLifeModel.womenLifeExpectation.defaultValue) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.humanLifeModel.nbOfYearsOfdependency.defaultValue,
                    in    : 0 ... 10) {
                HStack {
                    Text("Nombre d'années de dépendance")
                    Spacer()
                    Text("\(Int(viewModel.humanLifeModel.nbOfYearsOfdependency.defaultValue)) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.humanLifeModel.nbOfYearsOfdependency.defaultValue) { _ in viewModel.isModified = true }
        }
    }
}

struct ModelDeterministicHumanView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        let viewModel = DeterministicViewModel(using: model)
        return Form {
            ModelDeterministicHumanView()
                .environmentObject(viewModel)
        }
        .preferredColorScheme(.dark)
    }
}
