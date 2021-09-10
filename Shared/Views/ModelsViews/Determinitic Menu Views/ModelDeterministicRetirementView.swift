//
//  ModelDeterministicRetirementView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import ModelEnvironment

// MARK: - Deterministic Retirement View

struct ModelDeterministicRetirementView: View {
    @ObservedObject var viewModel: DeterministicViewModel
    @State private var isExpanded: Bool = true
    
    var body: some View {
        Section(header: Text("Modèle Retraite")) {
            DisclosureGroup("Régime Général",
                            isExpanded: $isExpanded) {
                Stepper(value : $viewModel.ageMinimumLegal,
                        in    : 50 ... 100) {
                    HStack {
                        Text("Age minimum légal de liquidation")
                        Spacer()
                        Text("\(viewModel.ageMinimumLegal) ans").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.ageMinimumLegal) { _ in viewModel.isModified = true }
            }
            
            DisclosureGroup("Régime Complémentaire",
                            isExpanded: $isExpanded) {
                Stepper(value : $viewModel.ageMinimumAGIRC,
                        in    : 50 ... 100) {
                    HStack {
                        Text("Age minimum de liquidation")
                        Spacer()
                        Text("\(viewModel.ageMinimumAGIRC) ans").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.ageMinimumAGIRC) { _ in viewModel.isModified = true }
                
                AmountView(label  : "Valeur du point",
                           amount : viewModel.valeurDuPointAGIRC,
                           digit: 4)
            }
        }
    }
}

struct ModelDeterministicRetirementView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        Form {
            ModelDeterministicRetirementView(viewModel: DeterministicViewModel(using: model))
        }
    }
}
