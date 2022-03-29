//
//  ModelDeterministicFiscalView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelDeterministicFiscalView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: Fiscal.Model
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            AmountEditView(label  : "Plafond Annuel de la Sécurité Sociale",
                           comment: "PASS",
                           amount : $subModel.PASS)

            Section(header: Text("Impôts").font(.headline)) {
                NavigationLink(destination: ModelFiscalIrppView(updateDependenciesToModel: updateDependenciesToModel,
                                                                subModel: $subModel.incomeTaxes.model.transaction())) {
                    Text("Revenus du Travail (IRPP)")
                    Spacer()
                    VersionVStackView(version: subModel.incomeTaxes.model.version,
                                      withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalIsfView(updateDependenciesToModel: updateDependenciesToModel,
                                                               subModel: $subModel.isf.model.transaction())) {
                    Text("Capital (IFI)")
                    Spacer()
                    VersionVStackView(version: subModel.isf.model.version,
                                      withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalImpotSocieteView(updateDependenciesToModel: updateDependenciesToModel,
                                                                        subModel: $subModel.companyProfitTaxes.model.transaction())) {
                    Text("Bénéfice des Sociétés (IS)")
                    Spacer()
                    VersionVStackView(version: subModel.companyProfitTaxes.model.version,
                                      withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalImmobilierImpotView(updateDependenciesToModel: updateDependenciesToModel,
                                                                           subModel: $subModel.estateCapitalGainIrpp.model.transaction())) {
                    Text("Plus-Value Immobilière")
                    Spacer()
                    VersionVStackView(version: subModel.estateCapitalGainIrpp.model.version,
                                      withDetails: false)
                }
            }
            
            Section(header: Text("Charges Sociales").font(.headline)) {
                NavigationLink(destination: ModelFiscalPensionView(updateDependenciesToModel: updateDependenciesToModel,
                                                                   subModel: $subModel.pensionTaxes.model.transaction())) {
                        Text("Pensions de Retraite")
                        Spacer()
                        VersionVStackView(version: subModel.pensionTaxes.model.version,
                                          withDetails: false)
                    }
                
                NavigationLink(destination: ModelFiscalChomageChargeView(updateDependenciesToModel: updateDependenciesToModel,
                                                                         subModel: $subModel.allocationChomageTaxes.model.transaction())) {
                        Text("Allocation Chômage")
                        Spacer()
                        VersionVStackView(version: subModel.allocationChomageTaxes.model.version,
                                          withDetails: false)
                    }
                
                NavigationLink(destination: ModelFiscalFinancialView(updateDependenciesToModel: updateDependenciesToModel,
                                                                     subModel: $subModel.financialRevenuTaxes.model.transaction())) {
                        Text("Revenus Financiers")
                        Spacer()
                        VersionVStackView(version: subModel.financialRevenuTaxes.model.version,
                                          withDetails: false)
                    }
                
                NavigationLink(destination: ModelFiscalLifeInsuranceView(updateDependenciesToModel: updateDependenciesToModel,
                                                                         subModel: $subModel.lifeInsuranceTaxes.model.transaction())) {
                        Text("Revenus d'Assurance Vie")
                        Spacer()
                        VersionVStackView(version: subModel.lifeInsuranceTaxes.model.version,
                                          withDetails: false)
                    }
                
                NavigationLink(destination: ModelFiscalTurnoverView(updateDependenciesToModel: updateDependenciesToModel,
                                                                    subModel: $subModel.turnoverTaxes.model.transaction())) {
                        Text("Bénéfices Non Commerciaux (BNC)")
                        Spacer()
                        VersionVStackView(version: subModel.turnoverTaxes.model.version,
                                          withDetails: false)
                    }
                
                NavigationLink(destination: ModelFiscalImmobilierTaxeView(updateDependenciesToModel: updateDependenciesToModel,
                                                                          subModel: $subModel.estateCapitalGainTaxes.model.transaction())) {
                        Text("Plus-Value Immobilière")
                        Spacer()
                        VersionVStackView(version: subModel.estateCapitalGainTaxes.model.version,
                                          withDetails: false)
                    }
            }
            
            Section(header: Text("Taxes").font(.headline)) {
                NavigationLink(destination: DemembrementGridView(label: "Barême de Démembrement",
                                                                 grid: $subModel.demembrement.model.grid.transaction(),
                                                                 updateDependenciesToModel: updateDependenciesToModel)) {
                    Text("Barême de Démembrement")
                }.isDetailLink(true)
                
                NavigationLink(destination: ModelFiscalInheritanceDonationView(updateDependenciesToModel: updateDependenciesToModel,
                                                                               subModel: $subModel.inheritanceDonation.model.transaction())) {
                    Text("Succession et Donation")
                    Spacer()
                    VersionVStackView(version: subModel.inheritanceDonation.model.version,
                                      withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalLifeInsInheritanceView(updateDependenciesToModel: updateDependenciesToModel,
                                                                              subModel: $subModel.lifeInsuranceInheritance.model.transaction())) {
                    Text("Transmission des Assurances Vie")
                    Spacer()
                    VersionVStackView(version: subModel.lifeInsuranceInheritance.model.version,
                                      withDetails: false)
                }
            }
        }
        .navigationTitle("Modèle Fiscal")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelDeterministicFiscalView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelDeterministicFiscalView(updateDependenciesToModel: { },
                                            subModel: .init(source: TestEnvir.model.fiscalModel))
        .preferredColorScheme(.dark)
    }
}
