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

// MARK: - Deterministic HumanLife View

struct ModelDeterministicHumanView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @StateObject private var viewModel        : DeterministicViewModel
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Stepper(value : $viewModel.humanLifeModel.menLifeExpectation.defaultValue,
                    in    : 50 ... 100) {
                HStack {
                    Text("Espérance de vie d'un Homme")
                    Spacer()
                    Text("\(Int(viewModel.humanLifeModel.menLifeExpectation.defaultValue)) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.humanLifeModel.menLifeExpectation.defaultValue) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.humanLifeModel.womenLifeExpectation.defaultValue,
                    in    : 50 ... 100) {
                HStack {
                    Text("Espérance de vie d'une Femme")
                    Spacer()
                    Text("\(Int(viewModel.humanLifeModel.womenLifeExpectation.defaultValue)) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.humanLifeModel.womenLifeExpectation.defaultValue) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.humanLifeModel.nbOfYearsOfdependency.defaultValue,
                    in    : 0 ... 10) {
                HStack {
                    Text("Nombre d'années de dépendance")
                    Spacer()
                    Text("\(Int(viewModel.humanLifeModel.nbOfYearsOfdependency.defaultValue)) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.humanLifeModel.nbOfYearsOfdependency.defaultValue) { _ in viewModel.isModified = true }
        }
        .navigationTitle("Modèle Humain")
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

//struct ModelDeterministicHumanView_Previews: PreviewProvider {
//    static var model = Model(fromBundle: Bundle.main)
//
//    static var previews: some View {
//        let viewModel = DeterministicViewModel(using: model)
//        return Form {
//            ModelDeterministicHumanView()
//                .environmentObject(viewModel)
//        }
//        .preferredColorScheme(.dark)
//    }
//}
