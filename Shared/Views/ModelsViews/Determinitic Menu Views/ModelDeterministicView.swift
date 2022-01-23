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
            VStack {
                Form {
                    // modèle vie humaine
                    ModelDeterministicHumanView(viewModel: viewModel)
                    
                    // modèle écnonomie
                    ModelDeterministicEconomyView(viewModel: viewModel)
                    
                    // modèle sociologie
                    ModelDeterministicSociologyView(viewModel: viewModel)
                    
                    // modèle retraite
                    ModelDeterministicRetirementView(viewModel: viewModel)

                    // modèle fiscal
                    ModelDeterministicFiscalView(viewModel: viewModel)

                    // modèle chômage
                    ModelDeterministicUnemploymentView(viewModel: viewModel)
                }
                .navigationTitle("Modèle Déterministe")
                .alert(item: $alertItem, content: newAlert)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        DiskButton(text   : "Modifier le Patron",
                                   action : applyChangesToTemplate)
                    }
                    ToolbarItem(placement: .automatic) {
                        FolderButton(action : applyChangesInMemory)
                            .disabled(!changeOccured)
                    }
                }
            }
            .onAppear {
                viewModel.updateFrom(model)
            }
        } else {
            NoLoadedDossierView()
        }
    }
    
    // MARK: - Properties
    
    var changeOccured: Bool {
        viewModel.isModified
    }

    // MARK: - Initialization
    
    init(using model: Model) {
        _viewModel = StateObject(wrappedValue: DeterministicViewModel(using: model))
    }
    
    // MARK: - Methods
    
    /// Appliquer la modification au projet ouvert (en mémoire seulement)
    ///
    /// - Warning:
    ///     Ne suvegarde PAS la modification sur disque
    ///
    func applyChangesInMemory() {
        alertItem =
            AlertItem(title         : Text("Dossier Ouvert"),
                      message       : Text("Voulez-vous appliquer les modifications effectuées au dossier ouvert ?\n Pensez à sauvegarder les modifications."),
                      primaryButton : .default(Text("Appliquer")) {
                        // mettre à jour le modèle avec les nouvelles valeurs
                        viewModel.update(model)
                        // mettre à jour les membres de la famille existants avec les nouvelles valeurs
                        viewModel.update(family)
                        // invalider les résultats de simulation existants
                        simulation.notifyComputationInputsModification()
                      },
                      secondaryButton: .cancel(Text("Revenir")) {
                        viewModel.updateFrom(model)
                      })
    }
    
    /// Enregistrer la modification dans le répertoire Template (sur disque)
    ///
    /// - Warning:
    ///     N'applique PAS la modification au projet ouvert (en mémoire)
    ///
    func applyChangesToTemplate() {
        alertItem =
            AlertItem(title         : Text("Modèle"),
                      message       : Text("Voulez-vous appliquer les modifications effectuées au modèle ?"),
                      primaryButton : .default(Text("Appliquer")) {
                        guard let templateFolder = PersistenceManager.templateFolder() else {
                            alertItem =
                                AlertItem(title         : Text("Répertoire 'Modèle' absent"),
                                          dismissButton : .default(Text("OK")))
                            return
                        }
                        
                        // créer une copie du modèle
                        let copy = Model(from: model)
                        // mettre à jour la copie du modèle avec les nouvelles valeurs
                        let wasModified = viewModel.isModified
                        viewModel.update(copy)
                        viewModel.isModified = wasModified

                        // sauvegarder la copie modifiée du modèle dans le dossier template
                        do {
                            try copy.saveAsJSON(toFolder: templateFolder)
                        } catch {
                            alertItem =
                                AlertItem(title         : Text("Echec de l'enregistrement"),
                                          dismissButton : .default(Text("OK")))
                        }
                      },
                      secondaryButton: .cancel())
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
