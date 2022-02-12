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
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            VersionEditableView(version: $model.fiscalModel.inheritanceDonation.model.version)
                .onChange(of: model.fiscalModel.inheritanceDonation.model.version) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

            Section(header: Text("Entre Conjoint").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême Donation Conjoint",
                                                         grid: $model.fiscalModel.inheritanceDonation.model.gridDonationConjoint)
                                .environmentObject(model)) {
                    Text("Barême pour Donation entre Conjoint")
                }.isDetailLink(true)
                
                AmountEditView(label  : "Abattement sur Donation au Conjoint",
                               amount : $model.fiscalModel.inheritanceDonation.model.abatConjoint)
                    .onChange(of: model.fiscalModel.inheritanceDonation.model.abatConjoint) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            Section(header: Text("En Ligne Directe").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême Donation Ligne Directe",
                                                         grid: $model.fiscalModel.inheritanceDonation.model.gridLigneDirecte)
                                .environmentObject(model)) {
                    Text("Barême pour Donation en Ligne Directe")
                }.isDetailLink(true)
                
                AmountEditView(label  : "Abattement sur Donation/Succession en ligne directe",
                               amount : $model.fiscalModel.inheritanceDonation.model.abatLigneDirecte)
                    .onChange(of: model.fiscalModel.inheritanceDonation.model.abatLigneDirecte) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            AmountEditView(label  : "Abattement sur Succession pour frais Funéraires",
                           amount : $model.fiscalModel.inheritanceDonation.model.fraisFunéraires)
                .onChange(of: model.fiscalModel.inheritanceDonation.model.fraisFunéraires) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            
            Stepper(value : $model.fiscalModel.inheritanceDonation.model.decoteResidence,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Décote sur la Résidence Principale")
                    Spacer()
                    Text("\(model.fiscalModel.inheritanceDonation.model.decoteResidence.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.inheritanceDonation.model.decoteResidence) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }
        }
        .navigationTitle("Succession et Donation")
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

struct ModelFiscalInheritanceDonationView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelFiscalInheritanceDonationView()
            .preferredColorScheme(.dark)
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
