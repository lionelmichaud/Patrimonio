//
//  ModelUnemploymentDelayView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import ModelEnvironment
import FamilyModel

struct ModelUnemploymentAmountView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Cas n°1").font(.headline)) {
                Stepper(value : $viewModel.unemploymentModel.allocationChomage.model.amountModel.case1Rate,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cas 1: % du salaire journalier de référence")
                        Spacer()
                        Text("\(viewModel.unemploymentModel.allocationChomage.model.amountModel.case1Rate.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.unemploymentModel.allocationChomage.model.amountModel.case1Rate) { _ in viewModel.isModified = true }

                AmountEditView(label  : "Cas 1: Indemnité journalière",
                               amount : $viewModel.unemploymentModel.allocationChomage.model.amountModel.case1Fix)
                    .onChange(of: viewModel.unemploymentModel.allocationChomage.model.amountModel.case1Fix) { _ in viewModel.isModified = true }
            }

            Section(header: Text("Cas n°2").font(.headline),
                    footer: Text("Le cas le plus favorable au demandeur d'emploi est retenu")) {
                Stepper(value : $viewModel.unemploymentModel.allocationChomage.model.amountModel.case2Rate,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cas 2: % du salaire journalier de référence")
                        Spacer()
                        Text("\(viewModel.unemploymentModel.allocationChomage.model.amountModel.case2Rate.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.unemploymentModel.allocationChomage.model.amountModel.case2Rate) { _ in viewModel.isModified = true }
            }

            Section(header: Text("Limites").font(.headline)) {
                AmountEditView(label  : "Allocation minimale",
                               amount : $viewModel.unemploymentModel.allocationChomage.model.amountModel.minAllocationEuro)
                    .onChange(of: viewModel.unemploymentModel.allocationChomage.model.amountModel.minAllocationEuro) { _ in viewModel.isModified = true }

                AmountEditView(label  : "Allocation maximale",
                               amount : $viewModel.unemploymentModel.allocationChomage.model.amountModel.maxAllocationEuro)
                    .onChange(of: viewModel.unemploymentModel.allocationChomage.model.amountModel.maxAllocationEuro) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.unemploymentModel.allocationChomage.model.amountModel.maxAllocationPcent,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Allocation maximale en % du salaire journalier de référence")
                        Spacer()
                        Text("\(viewModel.unemploymentModel.allocationChomage.model.amountModel.maxAllocationPcent.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.unemploymentModel.allocationChomage.model.amountModel.maxAllocationPcent) { _ in viewModel.isModified = true }
            }
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
        .navigationTitle("Calcul du montant de l'indemnité de recherche d'emploi")
    }
}

struct ModelUnemploymentDelayView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelUnemploymentAmountView()
            .environmentObject(viewModel)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
