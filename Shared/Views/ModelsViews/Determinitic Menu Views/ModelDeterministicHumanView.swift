//
//  ModelDeterministicHumanView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel
import HelpersView

// MARK: - Deterministic HumanLife View

struct ModelDeterministicHumanView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            Section(header: Text("Homme").font(.headline)) {
                VersionEditableViewInForm(version: $model.humanLifeModel.menLifeExpectation.version)
                    .onChange(of: model.humanLifeModel.menLifeExpectation.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
                
                Stepper(value : $model.humanLifeModel.menLifeExpectation.defaultValue,
                        in    : 50 ... 100) {
                    HStack {
                        Text("Espérance de vie d'un Homme")
                        Spacer()
                        Text("\(Int(model.humanLifeModel.menLifeExpectation.defaultValue)) ans").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.humanLifeModel.menLifeExpectation.defaultValue) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }

            Section(header: Text("Femme").font(.headline)) {
                VersionEditableViewInForm(version: $model.humanLifeModel.womenLifeExpectation.version)

                Stepper(value : $model.humanLifeModel.womenLifeExpectation.defaultValue,
                        in    : 50 ... 100) {
                    HStack {
                        Text("Espérance de vie d'une Femme")
                        Spacer()
                        Text("\(Int(model.humanLifeModel.womenLifeExpectation.defaultValue)) ans").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.humanLifeModel.womenLifeExpectation.defaultValue) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }

            Section(header: Text("Dépendance").font(.headline)) {
                VersionEditableViewInForm(version: $model.humanLifeModel.nbOfYearsOfdependency.version)

                Stepper(value : $model.humanLifeModel.nbOfYearsOfdependency.defaultValue,
                        in    : 0 ... 10) {
                    HStack {
                        Text("Nombre d'années de dépendance")
                        Spacer()
                        Text("\(Int(model.humanLifeModel.nbOfYearsOfdependency.defaultValue)) ans").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.humanLifeModel.nbOfYearsOfdependency.defaultValue) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
        }
        .navigationTitle("Modèle Humain")
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

struct ModelDeterministicHumanView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelDeterministicHumanView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
