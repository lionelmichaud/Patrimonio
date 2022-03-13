//
//  ModelFiscalChomageChargeView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel
import HelpersView

struct ModelFiscalChomageChargeView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $model.fiscalModel.allocationChomageTaxes.model.version)
                    .onChange(of: model.fiscalModel.allocationChomageTaxes.model.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            Stepper(value : $model.fiscalModel.allocationChomageTaxes.model.assiette,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("Assiette")
                    Spacer()
                    Text("\(model.fiscalModel.allocationChomageTaxes.model.assiette.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.allocationChomageTaxes.model.assiette) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            AmountEditView(label  : "Seuil de Taxation CSG/CRDS",
                           comment: "journalier",
                           amount : $model.fiscalModel.allocationChomageTaxes.model.seuilCsgCrds)
                .onChange(of: model.fiscalModel.allocationChomageTaxes.model.seuilCsgCrds) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

            Stepper(value : $model.fiscalModel.allocationChomageTaxes.model.CRDS,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("CRDS")
                    Spacer()
                    Text("\(model.fiscalModel.allocationChomageTaxes.model.CRDS.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.allocationChomageTaxes.model.CRDS) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            Stepper(value : $model.fiscalModel.allocationChomageTaxes.model.CSG,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("CSG")
                    Spacer()
                    Text("\(model.fiscalModel.allocationChomageTaxes.model.CSG.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.allocationChomageTaxes.model.CSG) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            Stepper(value : $model.fiscalModel.allocationChomageTaxes.model.retraiteCompl,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("Cotisation de Retraite Complémentaire")
                    Spacer()
                    Text("\(model.fiscalModel.allocationChomageTaxes.model.retraiteCompl.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.allocationChomageTaxes.model.retraiteCompl) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            AmountEditView(label  : "Seuil de Taxation Retraite Complémentaire",
                           comment: "journalier",
                           amount : $model.fiscalModel.allocationChomageTaxes.model.seuilRetCompl)
                .onChange(of: model.fiscalModel.allocationChomageTaxes.model.seuilRetCompl) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
        }
        .navigationTitle("Allocation Chômage")
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

struct ModelFiscalChomageChargeView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelFiscalChomageChargeView()
            .preferredColorScheme(.dark)
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
