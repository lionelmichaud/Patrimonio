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
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.incomeTaxes.model.version)
                    }

                    NavigationLink(destination: ModelFiscalIsfView()
                                    .environmentObject(viewModel)) {
                        Text("Capital (IFI)")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.isf.model.version)
                    }

                    NavigationLink(destination: ModelFiscalImpotSocieteView()
                                    .environmentObject(viewModel)) {
                        Text("Bénéfice des Sociétés (IS)")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.companyProfitTaxes.model.version)
                    }

                    NavigationLink(destination: ModelFiscalImmobilierImpotView()
                                    .environmentObject(viewModel)) {
                        Text("Plus-Value Immobilière")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.estateCapitalGainIrpp.model.version)
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
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.pensionTaxes.model.version)
                    }

                    NavigationLink(destination: ModelFiscalChomageChargeView()
                                    .environmentObject(viewModel)) {
                        Text("Allocation Chômage")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.allocationChomageTaxes.model.version)
                    }

                    NavigationLink(destination: ModelFiscalFinancialView()
                                    .environmentObject(viewModel)) {
                        Text("Revenus Financiers")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.financialRevenuTaxes.model.version)
                    }

                    NavigationLink(destination: ModelFiscalLifeInsuranceView()
                                    .environmentObject(viewModel)) {
                        Text("Revenus d'Assurance Vie")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.lifeInsuranceTaxes.model.version)
                    }

                    NavigationLink(destination: ModelFiscalTurnoverView()
                                    .environmentObject(viewModel)) {
                        Text("Bénéfices Non Commerciaux (BNC)")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.turnoverTaxes.model.version)
                    }

                    NavigationLink(destination: ModelFiscalImmobilierTaxeView()
                                    .environmentObject(viewModel)) {
                        Text("Plus-Value Immobilière")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.estateCapitalGainTaxes.model.version)
                    }
                },
                label: {
                    Text("Charges Sociales").bold().font(.headline)
                })
            
            DisclosureGroup(
                content: {
                    NavigationLink(destination: DemembrementGridView(label: "Barême de Démembrement",
                                                                     grid: $viewModel.fiscalModel.demembrement.model.grid)
                                    .environmentObject(viewModel)) {
                        Text("Barême de Démembrement")
                    }.isDetailLink(true)

                    NavigationLink(destination: ModelFiscalInheritanceDonationView()
                                    .environmentObject(viewModel)) {
                        Text("Succession et Donation")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.inheritanceDonation.model.version)
                    }

                    NavigationLink(destination: ModelFiscalLifeInsInheritanceView()
                                    .environmentObject(viewModel)) {
                        Text("Transmission des Assurances Vie")
                        Spacer()
                        VersionText(version: viewModel.fiscalModel.lifeInsuranceInheritance.model.version)
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
