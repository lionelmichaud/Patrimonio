//
//  ModelUnemploymentDelayView.swift
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

struct ModelUnemploymentAmountView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Cas n°1").font(.headline)) {
                Stepper(value : $model.unemploymentModel.allocationChomage.model.amountModel.case1Rate,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cas 1: % du salaire journalier de référence")
                        Spacer()
                        Text("\(model.unemploymentModel.allocationChomage.model.amountModel.case1Rate.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
                
                AmountEditView(label  : "Cas 1: Indemnité journalière",
                               amount : $model.unemploymentModel.allocationChomage.model.amountModel.case1Fix)
            }

            Section(header: Text("Cas n°2").font(.headline),
                    footer: Text("Le cas le plus favorable au demandeur d'emploi est retenu")) {
                Stepper(value : $model.unemploymentModel.allocationChomage.model.amountModel.case2Rate,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cas 2: % du salaire journalier de référence")
                        Spacer()
                        Text("\(model.unemploymentModel.allocationChomage.model.amountModel.case2Rate.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Limites").font(.headline)) {
                AmountEditView(label  : "Allocation minimale",
                               amount : $model.unemploymentModel.allocationChomage.model.amountModel.minAllocationEuro)

                AmountEditView(label  : "Allocation maximale",
                               amount : $model.unemploymentModel.allocationChomage.model.amountModel.maxAllocationEuro)

                Stepper(value : $model.unemploymentModel.allocationChomage.model.amountModel.maxAllocationPcent,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Allocation maximale en % du salaire journalier de référence")
                        Spacer()
                        Text("\(model.unemploymentModel.allocationChomage.model.amountModel.maxAllocationPcent.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: model.unemploymentModel.allocationChomage.model.amountModel) { _ in
            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
            model.manageInternalDependencies()
        }
        .navigationTitle("Calcul du montant de l'indemnité de recherche d'emploi")
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

struct ModelUnemploymentDelayView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelUnemploymentAmountView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
