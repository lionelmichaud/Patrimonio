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
    @EnvironmentObject private var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Sociologique").font(.headline)) {
            Stepper(value : $viewModel.socioEconomyModel.pensionDevaluationRate.defaultValue,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Dévaluation anuelle des pensions par rapport à l'inflation")
                    Spacer()
                    Text("\(viewModel.socioEconomyModel.pensionDevaluationRate.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.socioEconomyModel.pensionDevaluationRate.defaultValue) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.socioEconomyModel.nbTrimTauxPlein.defaultValue,
                    in    : 0 ... 12) {
                HStack {
                    Text("Nombre de trimestres additionels pour obtenir le taux plein")
                    Spacer()
                    Text("\(Int(viewModel.socioEconomyModel.nbTrimTauxPlein.defaultValue)) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.socioEconomyModel.nbTrimTauxPlein.defaultValue) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.socioEconomyModel.expensesUnderEvaluationRate.defaultValue,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Pénalisation des dépenses")
                    Spacer()
                    Text("\(viewModel.socioEconomyModel.expensesUnderEvaluationRate.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
                    .onChange(of: viewModel.socioEconomyModel.expensesUnderEvaluationRate.defaultValue) { _ in viewModel.isModified = true }
        }
    }
}

struct ModelDeterministicSociologyView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        let viewModel = DeterministicViewModel(using: model)
        return Form {
            ModelDeterministicSociologyView()
                .environmentObject(viewModel)
        }
        .preferredColorScheme(.dark)
    }
}
