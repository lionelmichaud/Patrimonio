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
                        Text("v\(viewModel.fiscalModel.incomeTaxes.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.incomeTaxes.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalIsfView()
                                    .environmentObject(viewModel)) {
                        Text("Capital (IFI)")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.isf.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.isf.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalImpotSocieteView()
                                    .environmentObject(viewModel)) {
                        Text("Bénéfice des Sociétés (IS)")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.companyProfitTaxes.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.companyProfitTaxes.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalImmobilierImpotView()
                                    .environmentObject(viewModel)) {
                        Text("Plus-Value Immobilière")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.estateCapitalGainIrpp.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.estateCapitalGainIrpp.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
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
                        Text("v\(viewModel.fiscalModel.pensionTaxes.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.pensionTaxes.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalChomageChargeView()
                                    .environmentObject(viewModel)) {
                        Text("Allocation Chômage")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.allocationChomageTaxes.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.allocationChomageTaxes.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalFinancialView()
                                    .environmentObject(viewModel)) {
                        Text("Revenus Financiers")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.financialRevenuTaxes.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.financialRevenuTaxes.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalLifeInsuranceView()
                                    .environmentObject(viewModel)) {
                        Text("Revenus d'Assurance Vie")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.lifeInsuranceTaxes.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.lifeInsuranceTaxes.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalTurnoverView()
                                    .environmentObject(viewModel)) {
                        Text("Bénéfices Non Commerciaux (BNC)")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.turnoverTaxes.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.turnoverTaxes.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalImmobilierTaxeView()
                                    .environmentObject(viewModel)) {
                        Text("Plus-Value Immobilière")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.estateCapitalGainTaxes.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.estateCapitalGainTaxes.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
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
                        Text("v\(viewModel.fiscalModel.inheritanceDonation.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.inheritanceDonation.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
                    }

                    NavigationLink(destination: ModelFiscalLifeInsInheritanceView()
                                    .environmentObject(viewModel)) {
                        Text("Transmission des Assurances Vie")
                        Spacer()
                        Text("v\(viewModel.fiscalModel.lifeInsuranceInheritance.model.version.version ?? "")")
                            .foregroundColor(.secondary)
                        Text("du \(viewModel.fiscalModel.lifeInsuranceInheritance.model.version.date.stringShortDate)")
                            .foregroundColor(.secondary)
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
