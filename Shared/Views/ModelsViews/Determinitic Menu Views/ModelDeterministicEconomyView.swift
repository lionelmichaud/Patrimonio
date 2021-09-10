//
//  ModelDeterministicEconomyModel.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import ModelEnvironment

// MARK: - Deterministic Economy View

struct ModelDeterministicEconomyView: View {
    @ObservedObject var viewModel: DeterministicViewModel
    
    var body: some View {
        return Section(header: Text("Modèle Economique")) {
            Stepper(value : $viewModel.inflation,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Inflation")
                    Spacer()
                    Text("\(viewModel.inflation.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
            .onChange(of: viewModel.inflation) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.securedRate,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Rendement sans Risque")
                    Spacer()
                    Text("\(viewModel.securedRate.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
            .onChange(of: viewModel.securedRate) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.stockRate,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Rendement des Actions")
                    Spacer()
                    Text("\(viewModel.stockRate.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
            .onChange(of: viewModel.stockRate) { _ in viewModel.isModified = true }
        }
    }
}

struct ModelDeterministicEconomyView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        Form {
            ModelDeterministicEconomyView(viewModel: DeterministicViewModel(using: model))
        }
    }
}
