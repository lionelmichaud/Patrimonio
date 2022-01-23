//
//  ModelDeterministicFiscalView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI

struct ModelDeterministicFiscalView: View {
    @ObservedObject var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Fiscal").font(.headline)) {
            AmountEditView(label  : "Plafond Annuel de la Sécurité Sociale",
                           amount : $viewModel.fiscalModel.PASS)
                .onChange(of: viewModel.fiscalModel.PASS) { _ in viewModel.isModified = true }
            
            NavigationLink(destination: ModelFiscalIrppView(viewModel: viewModel)) {
                Text("Imposition sur le Revenu (IRPP)")
            }
            
            NavigationLink(destination: ModelFiscalIsfView(viewModel: viewModel)) {
                Text("Imposition sur le Capital (IFI)")
            }
            
            NavigationLink(destination: ModelFiscalPensionView(viewModel: viewModel)) {
                Text("Imposition sur les Pensions de Retraite")
            }
            
            NavigationLink(destination: ModelFiscalFinancialView(viewModel: viewModel)) {
                Text("Imposition sur les Revenus Financiers")
            }
            
            NavigationLink(destination: ModelFiscalLifeInsuranceView(viewModel: viewModel)) {
                Text("Imposition sur les Revenus d'Assurance Vie")
            }
            
            NavigationLink(destination: ModelFiscalInheritanceDonationView(viewModel: viewModel)) {
                Text("Droits de Succession et Donation")
            }
            
            NavigationLink(destination: ModelFiscalLifeInsInheritanceView(viewModel: viewModel)) {
                Text("Taxes sur la Transmission des Assurances Vie")
            }
        }
    }
}

struct ModelDeterministicFiscalView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelDeterministicFiscalView(viewModel: DeterministicViewModel(using: modelTest))
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
