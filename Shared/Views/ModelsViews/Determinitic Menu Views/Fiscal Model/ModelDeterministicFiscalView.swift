//
//  ModelDeterministicFiscalView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI

struct ModelDeterministicFiscalView: View {
    @EnvironmentObject private var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Fiscal").font(.headline)) {
            AmountEditView(label  : "Plafond Annuel de la Sécurité Sociale",
                           comment: "PASS",
                           amount : $viewModel.fiscalModel.PASS)
                .onChange(of: viewModel.fiscalModel.PASS) { _ in viewModel.isModified = true }

            DisclosureGroup(
                content: {
                    NavigationLink(destination: ModelFiscalIrppView()
                                    .environmentObject(viewModel)) {
                        Text("Revenus du Travail (IRPP)")
                    }

                    NavigationLink(destination: ModelFiscalIsfView()
                                    .environmentObject(viewModel)) {
                        Text("Capital (IFI)")
                    }

                    NavigationLink(destination: ModelFiscalImpotSocieteView()
                                    .environmentObject(viewModel)) {
                        Text("Bénéfice des Sociétés (IS)")
                    }

                    NavigationLink(destination: ModelFiscalImmobilierImpotView()
                                    .environmentObject(viewModel)) {
                        Text("Plus-Value Immobilière")
                    }
                },
                label: {
                    Text("Impôts").bold().font(.headline)
                })

            DisclosureGroup(
                content: {
                    NavigationLink(destination: ModelFiscalPensionView()
                                    .environmentObject(viewModel)) {
                        Text("Pensions de Retraite")
                    }

                    NavigationLink(destination: ModelFiscalChomageChargeView()
                                    .environmentObject(viewModel)) {
                        Text("Allocation Chômage")
                    }

                    NavigationLink(destination: ModelFiscalFinancialView()
                                    .environmentObject(viewModel)) {
                        Text("Revenus Financiers")
                    }

                    NavigationLink(destination: ModelFiscalLifeInsuranceView()
                                    .environmentObject(viewModel)) {
                        Text("Revenus d'Assurance Vie")
                    }

                    NavigationLink(destination: ModelFiscalTurnoverView()
                                    .environmentObject(viewModel)) {
                        Text("Bénéfices Non Commerciaux (BNC)")
                    }

                    NavigationLink(destination: ModelFiscalImmobilierTaxeView()
                                    .environmentObject(viewModel)) {
                        Text("Plus-Value Immobilière")
                    }
                },
                label: {
                    Text("Charges Sociales").bold().font(.headline)
                })
            
            DisclosureGroup(
                content: {
                    NavigationLink(destination: ModelFiscalInheritanceDonationView()
                                    .environmentObject(viewModel)) {
                        Text("Succession et Donation")
                    }

                    NavigationLink(destination: ModelFiscalLifeInsInheritanceView()
                                    .environmentObject(viewModel)) {
                        Text("Transmission des Assurances Vie")
                    }
                },
                label: {
                    Text("Taxes").bold().font(.headline)
                })
        }
    }
}

struct ModelDeterministicFiscalView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return
            Form {
                ModelDeterministicFiscalView()
                    .preferredColorScheme(.dark)
                    .environmentObject(modelTest)
                    .environmentObject(familyTest)
                    .environmentObject(simulationTest)
                    .environmentObject(viewModel)
            }
    }
}
