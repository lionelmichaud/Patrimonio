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
    @StateObject private var viewModel        : DeterministicViewModel
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            NavigationLink(destination:
                            UnemploymentAreDurationGridView(label: "Barême de durée d'indemnisation",
                                                            grid: $viewModel.unemploymentModel.allocationChomage.model.durationGrid)
                            .environmentObject(viewModel)) {
                Text("Durée d'indemnisation")
            }.isDetailLink(true)

            NavigationLink(destination: ModelUnemploymentAmountView()
                            .environmentObject(viewModel)) {
                Text("Différés d'indemnisation")
            }

            NavigationLink(destination: ModelUnemploymentDiffereView()
                            .environmentObject(viewModel)) {
                Text("Allocation de Recherche d'Emploi (ARE)")
            }
        }
        .navigationTitle("Modèle Economique")
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

//struct ModelDeterministicUnemploymentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ModelDeterministicUnemploymentView()
//    }
//}
