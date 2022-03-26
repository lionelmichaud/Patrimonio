//
//  ModelUnemploymentAmountView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel
import SimulationAndVisitors
import HelpersView

struct ModelUnemploymentDiffereView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Délai").font(.headline)) {
                Stepper(value : $model.unemploymentModel.allocationChomage.model.delayModel.delaiAttente,
                        in    : 0 ... 100) {
                    HStack {
                        Text("Délai d'attente avant inscription")
                        Spacer()
                        Text("\(model.unemploymentModel.allocationChomage.model.delayModel.delaiAttente) jours")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Différé Spécifique").font(.headline)) {
                Stepper(value : $model.unemploymentModel.allocationChomage.model.delayModel.ratioDiffereSpecifique,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Nombre de jours de différé obtenu en x le montant de l'indemnité par ce coefficient")
                        Spacer()
                        Text("\(model.unemploymentModel.allocationChomage.model.delayModel.ratioDiffereSpecifique.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $model.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifique,
                        in    : 0 ... 300) {
                    HStack {
                        Text("Durée maximale du différé spécifique")
                        Spacer()
                        Text("\(model.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifique) jours")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $model.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifiqueLicenciementEco,
                        in    : 0 ... 150) {
                    HStack {
                        Text("Sauf dans le cas d'un licenciement économique")
                        Spacer()
                        Text("\(model.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifiqueLicenciementEco) jours")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: model.unemploymentModel.allocationChomage.model.delayModel) { _ in
            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
            model.manageInternalDependencies()
        }
        .navigationTitle("Calcul du Différé d'indemnisation")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    model     : model,
                    notifyTemplatFolderMissing: {
                        DispatchQueue.main.async {
                            alertItem =
                            AlertItem(title         : Text("Répertoire 'Patron' absent"),
                                      dismissButton : .default(Text("OK")))
                        }
                    },
                    notifyFailure: {
                        DispatchQueue.main.async {
                            alertItem =
                            AlertItem(title         : Text("Echec de l'enregistrement"),
                                      dismissButton : .default(Text("OK")))
                        }
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

struct ModelUnemploymentAmountView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelUnemploymentDiffereView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
            .preferredColorScheme(.dark)
    }
}
