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
    @EnvironmentObject private var viewModel : DeterministicViewModel
    @State private var isExpandedSecuredRate : Bool = false
    @State private var isExpandedStockRate   : Bool = false

    var body: some View {
        return Section(header: Text("Modèle Economique").font(.headline)) {
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
            
            DisclosureGroup("Placements sans Risque",
                            isExpanded: $isExpandedSecuredRate) {
                Stepper(value : $viewModel.securedRate,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(viewModel.securedRate.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.securedRate) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.securedVolatility,
                        in    : 0 ... 5,
                        step  : 0.1) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(viewModel.securedVolatility.percentString(digit: 2)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.securedVolatility) { _ in viewModel.isModified = true }
            }
            
            DisclosureGroup("Placements Actions",
                            isExpanded: $isExpandedStockRate) {
                Stepper(value : $viewModel.stockRate,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(viewModel.stockRate.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.stockRate) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.stockVolatility,
                        in    : 0 ... 20,
                        step  : 1.0) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(viewModel.stockVolatility.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.stockVolatility) { _ in viewModel.isModified = true }
            }
        }
    }
}

struct ModelDeterministicEconomyView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        let viewModel = DeterministicViewModel(using: model)
        return Form {
            ModelDeterministicEconomyView()
                .environmentObject(viewModel)
        }
        .preferredColorScheme(.dark)
    }
}
