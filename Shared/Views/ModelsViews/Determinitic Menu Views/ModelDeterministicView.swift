//
//  ModelDeterministicView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Statistics
import HumanLifeModel
import EconomyModel
import SocioEconomyModel
import ModelEnvironment
import Persistence
import FamilyModel

// MARK: - Deterministic View

/// Affiche les valeurs déterministes retenues pour les paramètres des modèles dans une simulation "déterministe"
struct ModelDeterministicView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @StateObject private var viewModel        : DeterministicViewModel
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        if dataStore.activeDossier != nil {
            Form {
                // modèle vie humaine
                ModelDeterministicHumanView()
                    .environmentObject(viewModel)

                // modèle écnonomie
                ModelDeterministicEconomyView()
                    .environmentObject(viewModel)

                // modèle sociologie
                ModelDeterministicSociologyView()
                    .environmentObject(viewModel)

                // modèle retraite
                ModelDeterministicRetirementView()
                    .environmentObject(viewModel)

                // modèle fiscal
                ModelDeterministicFiscalView()
                    .environmentObject(viewModel)

                // modèle chômage
                ModelDeterministicUnemploymentView()
                    .environmentObject(viewModel)
            }
            .navigationTitle("Modèle Déterministe")
            .alert(item: $alertItem, content: newAlert)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    DiskButton(text   : "Modifier le Patron",
                               action : {
                                alertItem = applyChangesToTemplateAlert(
                                    viewModel: viewModel,
                                    model: model,
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
                               })
                }
                ToolbarItem(placement: .automatic) {
                    FolderButton(action : {
                        alertItem = applyChangesToOpenDossierAlert(
                            viewModel: viewModel,
                            model: model,
                            family: family,
                            simulation: simulation)
                    })
                    .disabled(!viewModel.isModified)
                }
            }
            .onAppear {
                viewModel.updateFrom(model)
            }
        } else {
            NoLoadedDossierView()
        }
    }
    
    // MARK: - Initialization
    
    init(using model: Model) {
        _viewModel = StateObject(wrappedValue: DeterministicViewModel(using: model))
    }
}

struct ModelDeterministicView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        dataStoreTest.activate(dossierAtIndex: 0)
        return ModelDeterministicView(using: modelTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
