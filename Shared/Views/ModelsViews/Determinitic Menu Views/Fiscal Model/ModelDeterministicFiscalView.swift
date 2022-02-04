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
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @StateObject private var viewModel        : DeterministicViewModel
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            AmountEditView(label  : "Plafond Annuel de la Sécurité Sociale",
                           comment: "PASS",
                           amount : $viewModel.fiscalModel.PASS)
                .onChange(of: viewModel.fiscalModel.PASS) { _ in viewModel.isModified = true }
            
            Section(header: Text("Impôts").font(.headline)) {
                NavigationLink(destination: ModelFiscalIrppView()
                                .environmentObject(viewModel)) {
                    Text("Revenus du Travail (IRPP)")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.incomeTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalIsfView()
                                .environmentObject(viewModel)) {
                    Text("Capital (IFI)")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.isf.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalImpotSocieteView()
                                .environmentObject(viewModel)) {
                    Text("Bénéfice des Sociétés (IS)")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.companyProfitTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalImmobilierImpotView()
                                .environmentObject(viewModel)) {
                    Text("Plus-Value Immobilière")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.estateCapitalGainIrpp.model.version,
                                withDetails: false)
                }
            }
            
            Section(header: Text("Charges Sociales").font(.headline)) {
                NavigationLink(destination: ModelFiscalPensionView()
                                .environmentObject(viewModel)) {
                    Text("Pensions de Retraite")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.pensionTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalChomageChargeView()
                                .environmentObject(viewModel)) {
                    Text("Allocation Chômage")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.allocationChomageTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalFinancialView()
                                .environmentObject(viewModel)) {
                    Text("Revenus Financiers")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.financialRevenuTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalLifeInsuranceView()
                                .environmentObject(viewModel)) {
                    Text("Revenus d'Assurance Vie")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.lifeInsuranceTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalTurnoverView()
                                .environmentObject(viewModel)) {
                    Text("Bénéfices Non Commerciaux (BNC)")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.turnoverTaxes.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalImmobilierTaxeView()
                                .environmentObject(viewModel)) {
                    Text("Plus-Value Immobilière")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.estateCapitalGainTaxes.model.version,
                                withDetails: false)
                }
            }
            
            Section(header: Text("Taxes").font(.headline)) {
                NavigationLink(destination: DemembrementGridView(label: "Barême de Démembrement",
                                                                 grid: $viewModel.fiscalModel.demembrement.model.grid)
                                .environmentObject(viewModel)) {
                    Text("Barême de Démembrement")
                }.isDetailLink(true)
                
                NavigationLink(destination: ModelFiscalInheritanceDonationView()
                                .environmentObject(viewModel)) {
                    Text("Succession et Donation")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.inheritanceDonation.model.version,
                                withDetails: false)
                }
                
                NavigationLink(destination: ModelFiscalLifeInsInheritanceView()
                                .environmentObject(viewModel)) {
                    Text("Transmission des Assurances Vie")
                    Spacer()
                    VersionText(version: viewModel.fiscalModel.lifeInsuranceInheritance.model.version,
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
                    viewModel : viewModel,
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
            applyChangesToDossier: {
                alertItem = applyChangesToOpenDossierAlert(
                    viewModel  : viewModel,
                    model      : model,
                    family     : family,
                    simulation : simulation)
            },
            isModified: viewModel.isModified)
        .onAppear {
            viewModel.updateFrom(model)
        }
    }
    
    // MARK: - Initialization
    
    init(using model: Model) {
        _viewModel = StateObject(wrappedValue: DeterministicViewModel(using: model))
    }
}

struct ModelDeterministicFiscalView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelDeterministicFiscalView(using: modelTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
