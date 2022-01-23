//
//  ModelDeterministicSociologyView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import ModelEnvironment

// MARK: - Deterministic SocioEconomy View

struct ModelDeterministicSociologyView: View {
    @ObservedObject var viewModel: DeterministicViewModel
    
    var body: some View {
        Section(header: Text("Modèle Sociologique").font(.headline)) {
            Stepper(value : $viewModel.pensionDevaluationRate,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Dévaluation anuelle des pensions par rapport à l'inflation")
                    Spacer()
                    Text("\(viewModel.pensionDevaluationRate.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
            .onChange(of: viewModel.pensionDevaluationRate) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.nbTrimTauxPlein,
                    in    : 0 ... 12) {
                HStack {
                    Text("Nombre de trimestres additionels pour obtenir le taux plein")
                    Spacer()
                    Text("\(viewModel.nbTrimTauxPlein) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.menLifeExpectation) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.expensesUnderEvaluationRate,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Pénalisation des dépenses")
                    Spacer()
                    Text("\(viewModel.expensesUnderEvaluationRate.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
            .onChange(of: viewModel.expensesUnderEvaluationRate) { _ in viewModel.isModified = true }
        }
    }
}

struct ModelDeterministicSociologyView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        Form {
            ModelDeterministicSociologyView(viewModel: DeterministicViewModel(using: model))
        }
    }
}
