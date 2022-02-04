//
//  ModelUnemploymentAmountView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import ModelEnvironment
import FamilyModel

struct ModelUnemploymentDiffereView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Délai").font(.headline)) {
                Stepper(value : $viewModel.unemploymentModel.allocationChomage.model.delayModel.delaiAttente,
                        in    : 0 ... 100) {
                    HStack {
                        Text("Délai d'attente avant inscription")
                        Spacer()
                        Text("\(viewModel.unemploymentModel.allocationChomage.model.delayModel.delaiAttente) jours").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.unemploymentModel.allocationChomage.model.delayModel.delaiAttente) { _ in viewModel.isModified = true }
            }

            Section(header: Text("Différé Spécifique").font(.headline)) {
                Stepper(value : $viewModel.unemploymentModel.allocationChomage.model.delayModel.ratioDiffereSpecifique,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Nombre de jours de différé obtenu en x le montant de l'indemnité par ce coefficient")
                        Spacer()
                        Text("\(viewModel.unemploymentModel.allocationChomage.model.delayModel.ratioDiffereSpecifique.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.unemploymentModel.allocationChomage.model.delayModel.ratioDiffereSpecifique) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifique,
                        in    : 0 ... 300) {
                    HStack {
                        Text("Durée maximale du différé spécifique")
                        Spacer()
                        Text("\(viewModel.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifique) jours").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifique) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifiqueLicenciementEco,
                        in    : 0 ... 150) {
                    HStack {
                        Text("Sauf dans le cas d'un licenciement économique")
                        Spacer()
                        Text("\(viewModel.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifiqueLicenciementEco) jours").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.unemploymentModel.allocationChomage.model.delayModel.maxDiffereSpecifiqueLicenciementEco) { _ in viewModel.isModified = true }
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
        .navigationTitle("Calcul du Différé d'indemnisation")
    }
}

struct ModelUnemploymentAmountView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelUnemploymentDiffereView()
            .environmentObject(viewModel)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
