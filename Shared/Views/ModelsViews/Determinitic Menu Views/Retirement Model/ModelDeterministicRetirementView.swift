//
//  ModelDeterministicRetirementView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel

// MARK: - Deterministic Retirement View

struct ModelDeterministicRetirementView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @StateObject private var viewModel        : DeterministicViewModel
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            NavigationLink(destination: ModelRetirementGeneralView()
                            .environmentObject(viewModel)) {
                Text("Pension du Régime Général")
                Spacer()
                VersionText(version: viewModel.retirementModel.regimeGeneral.model.version,
                            withDetails: false)
            }
            
            NavigationLink(destination: ModelRetirementAgircView()
                            .environmentObject(viewModel)) {
                Text("Pension du Régime Complémentaire")
                Spacer()
                VersionText(version: viewModel.retirementModel.regimeAgirc.model.version,
                            withDetails: false)
            }
            
            NavigationLink(destination: ModelRetirementReversionView()
                            .environmentObject(viewModel)) {
                Text("Pension de Réversion")
                Spacer()
                VersionText(version: viewModel.retirementModel.reversion.model.version,
                            withDetails: false)
            }
        }
        .navigationTitle("Modèle Retraite")
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

struct ModelDeterministicRetirementView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelDeterministicRetirementView(using: modelTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
