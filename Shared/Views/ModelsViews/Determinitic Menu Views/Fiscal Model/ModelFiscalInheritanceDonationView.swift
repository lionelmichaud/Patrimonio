//
//  ModelFiscalInheritanceDonationView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalInheritanceDonationView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            VersionView(version: $viewModel.fiscalModel.inheritanceDonation.model.version)
                .onChange(of: viewModel.fiscalModel.inheritanceDonation.model.version) { _ in viewModel.isModified = true }

            Section(header: Text("Entre Conjoint").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême Donation Conjoint",
                                                         grid: $viewModel.fiscalModel.inheritanceDonation.model.gridDonationConjoint)
                                .environmentObject(viewModel)) {
                    Text("Barême pour Donation entre Conjoint")
                }.isDetailLink(true)
                
                AmountEditView(label  : "Abattement sur Donation au Conjoint",
                               amount : $viewModel.fiscalModel.inheritanceDonation.model.abatConjoint)
                    .onChange(of: viewModel.fiscalModel.inheritanceDonation.model.abatConjoint) { _ in viewModel.isModified = true }
            }
            
            Section(header: Text("En Ligne Directe").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême Donation Ligne Directe",
                                                         grid: $viewModel.fiscalModel.inheritanceDonation.model.gridLigneDirecte)
                                .environmentObject(viewModel)) {
                    Text("Barême pour Donation en Ligne Directe")
                }.isDetailLink(true)
                
                AmountEditView(label  : "Abattement sur Donation/Succession en ligne directe",
                               amount : $viewModel.fiscalModel.inheritanceDonation.model.abatLigneDirecte)
                    .onChange(of: viewModel.fiscalModel.inheritanceDonation.model.abatLigneDirecte) { _ in viewModel.isModified = true }
            }
            
            AmountEditView(label  : "Abattement sur Succession pour frais Funéraires",
                           amount : $viewModel.fiscalModel.inheritanceDonation.model.fraisFunéraires)
                .onChange(of: viewModel.fiscalModel.inheritanceDonation.model.fraisFunéraires) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.fiscalModel.inheritanceDonation.model.decoteResidence,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Décote sur la Résidence Principale")
                    Spacer()
                    Text("\(viewModel.fiscalModel.inheritanceDonation.model.decoteResidence.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.inheritanceDonation.model.decoteResidence) { _ in viewModel.isModified = true }
        }
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
        .navigationTitle("Succession et Donation")
    }
}

struct ModelFiscalInheritanceDonationView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalInheritanceDonationView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
