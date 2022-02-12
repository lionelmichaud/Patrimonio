//
//  ModelDeterministicFiscalView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel

struct ModelDeterministicFiscalView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            AmountEditView(label  : "Plafond Annuel de la Sécurité Sociale",
                           comment: "PASS",
                           amount : $model.fiscalModel.PASS)
                .onChange(of: model.fiscalModel.PASS) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            
            Section(header: Text("Impôts").font(.headline)) {
                NavigationLink(destination: ModelFiscalIrppView()
                                .environmentObject(model)) {
                    Text("Revenus du Travail (IRPP)")
                    Spacer()
                    VersionText(version: model.fiscalModel.incomeTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalIsfView()
                                .environmentObject(model)) {
                    Text("Capital (IFI)")
                    Spacer()
                    VersionText(version: model.fiscalModel.isf.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalImpotSocieteView()
                                .environmentObject(model)) {
                    Text("Bénéfice des Sociétés (IS)")
                    Spacer()
                    VersionText(version: model.fiscalModel.companyProfitTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalImmobilierImpotView()
                                .environmentObject(model)) {
                    Text("Plus-Value Immobilière")
                    Spacer()
                    VersionText(version: model.fiscalModel.estateCapitalGainIrpp.model.version,
                                withDetails: false)
                }
            }
            
            Section(header: Text("Charges Sociales").font(.headline)) {
                NavigationLink(destination: ModelFiscalPensionView()
                                .environmentObject(model)) {
                    Text("Pensions de Retraite")
                    Spacer()
                    VersionText(version: model.fiscalModel.pensionTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalChomageChargeView()
                                .environmentObject(model)) {
                    Text("Allocation Chômage")
                    Spacer()
                    VersionText(version: model.fiscalModel.allocationChomageTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalFinancialView()
                                .environmentObject(model)) {
                    Text("Revenus Financiers")
                    Spacer()
                    VersionText(version: model.fiscalModel.financialRevenuTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalLifeInsuranceView()
                                .environmentObject(model)) {
                    Text("Revenus d'Assurance Vie")
                    Spacer()
                    VersionText(version: model.fiscalModel.lifeInsuranceTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalTurnoverView()
                                .environmentObject(model)) {
                    Text("Bénéfices Non Commerciaux (BNC)")
                    Spacer()
                    VersionText(version: model.fiscalModel.turnoverTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalImmobilierTaxeView()
                                .environmentObject(model)) {
                    Text("Plus-Value Immobilière")
                    Spacer()
                    VersionText(version: model.fiscalModel.estateCapitalGainTaxes.model.version,
                                withDetails: false)
                }
            }
            
            Section(header: Text("Taxes").font(.headline)) {
                NavigationLink(destination: DemembrementGridView(label: "Barême de Démembrement",
                                                                 grid: $model.fiscalModel.demembrement.model.grid)
                                .environmentObject(model)) {
                    Text("Barême de Démembrement")
                }.isDetailLink(true)
                
                NavigationLink(destination: ModelFiscalInheritanceDonationView()
                                .environmentObject(model)) {
                    Text("Succession et Donation")
                    Spacer()
                    VersionText(version: model.fiscalModel.inheritanceDonation.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalLifeInsInheritanceView()
                                .environmentObject(model)) {
                    Text("Transmission des Assurances Vie")
                    Spacer()
                    VersionText(version: model.fiscalModel.lifeInsuranceInheritance.model.version,
                                withDetails: false)
                }
            }
        }
        .navigationTitle("Modèle Fiscal")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    model     : model,
                    notifyTemplatFolderMissing: {
                        alertItem =
                            AlertItem(title         : Text("Répertoire 'Patron' absent"),
                                      dismissButton : .default(Text("OK")))
                    },
                    notifyFailure: {
                        alertItem =
                            AlertItem(title         : Text("Echec de l'enregistrement"),
                                      dismissButton : .default(Text("OK")))
                    })
            },
            cancelChanges: {
                alertItem = cancelChanges(
                    to         : model,
                    family     : family,
                    simulation : simulation,
                    dataStore  : dataStore)
            },
            isModified: model.isModified)
    }
}

struct ModelDeterministicFiscalView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelDeterministicFiscalView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
