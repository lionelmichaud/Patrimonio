//
//  ModelUpdateAlerts.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

// MARK: - Global Methods

/// Appliquer la modification au projet ouvert (en mémoire seulement)
///
/// - Warning:
///     Ne suvegarde PAS la modification sur disque
///
func applyChangesToOpenDossierAlert(viewModel  : DeterministicViewModel,
                                    model      : Model,
                                    family     : Family,
                                    simulation : Simulation) -> AlertItem {
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
func applyChangesToTemplateAlert(viewModel                  : DeterministicViewModel,
                                 model                      : Model,
                                 notifyTemplatFolderMissing : @escaping () -> Void,
                                 notifyFailure              : @escaping () -> Void) -> AlertItem {
    AlertItem(title         : Text("Modèle"),
              message       : Text("Voulez-vous appliquer les modifications effectuées au modèle ?"),
              primaryButton : .default(Text("Appliquer")) {
        guard let templateFolder = PersistenceManager.templateFolder() else {
            notifyTemplatFolderMissing()
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
            notifyFailure()
        }
    },
              secondaryButton: .cancel())
}

// MARK: - View Extensions

extension View {
    func modelChangesToolbar(applyChangesToTemplate: @escaping () -> Void,
                             applyChangesToDossier : @escaping () -> Void,
                             isModified            : Bool,
                             isValid               : Bool = true) -> some View {
        self.toolbar {
            ToolbarItem(placement: .automatic) {
                DiskButton(text   : "Modifier le Patron",
                           action : applyChangesToTemplate)
            }
            ToolbarItem(placement: .automatic) {
                FolderButton(action : applyChangesToDossier)
                    .disabled(!isModified || !isValid)
            }
        }
    }
}
