//
//  ModelDeterministicUnemploymentView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel

struct ModelDeterministicUnemploymentView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            VersionEditableView(version: $model.unemploymentModel.allocationChomage.model.version)
                .onChange(of: model.unemploymentModel.allocationChomage.model.version) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

            NavigationLink(destination:
                            UnemploymentAreDurationGridView(label: "Barême de durée d'indemnisation",
                                                            grid: $model.unemploymentModel.allocationChomage.model.durationGrid)
                            .environmentObject(model)) {
                Text("Durée d'indemnisation")
            }.isDetailLink(true)

            NavigationLink(destination: ModelUnemploymentAmountView()
                            .environmentObject(model)) {
                Text("Différés d'indemnisation")
            }

            NavigationLink(destination: ModelUnemploymentDiffereView()
                            .environmentObject(model)) {
                Text("Allocation de Recherche d'Emploi (ARE)")
            }
        }
        .navigationTitle("Modèle Chômage")
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

struct ModelDeterministicUnemploymentView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelDeterministicUnemploymentView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
