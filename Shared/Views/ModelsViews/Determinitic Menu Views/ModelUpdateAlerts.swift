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
import SimulationAndVisitors
import HelpersView

// MARK: - Global Methods

/// Recharger le modèle complet à partir du fichier JSON
/// et mettre à jour toutes les dépendances internes au modèle et externes vis-à-vis du modèle
func cancelChanges(to model   : Model,
                   family     : Family,
                   simulation : Simulation,
                   dataStore  : Store) -> AlertItem {
    AlertItem(title         : Text("Revenir au dossier sauvegardé"),
              message       : Text("Voulez-vous vraiement annuler toutes les modifications effectuées sur le modèle depuis l'ouverture du dossier ?"),
              primaryButton : .destructive(Text("Appliquer")) {
                /// recharger le modèle depuis le fichier JSON
                try! model.loadFromJSON(fromFolder: dataStore.activeDossier!.folder!)
                DependencyInjector.updateDependenciesToModel(model      : model,
                                                             family     : family,
                                                             simulation : simulation)
              },
              secondaryButton: .cancel())
}

/// Sauvegarder le modèle dans le dossier template
///
/// - Warning:
///     N'applique PAS la modification au projet ouvert (en mémoire)
///
func applyChangesToTemplateAlert(model                      : Model,
                                 notifyTemplatFolderMissing : @escaping () -> Void,
                                 notifyFailure              : @escaping () -> Void) -> AlertItem {
    AlertItem(title         : Text("Modèle"),
              message       : Text("Voulez-vous appliquer les modifications effectuées au patron ?"),
              primaryButton : .destructive(Text("Appliquer")) {
                guard let templateFolder = PersistenceManager.templateFolder() else {
                    notifyTemplatFolderMissing()
                    return
                }
                
                // sauvegarder la copie modifiée du modèle dans le dossier template
                do {
                    try model.saveAsJSON(toFolder: templateFolder)
                } catch {
                    notifyFailure()
                }
              },
              secondaryButton: .cancel())
}

// MARK: - View Extensions

extension View {
    func modelChangesToolbar(applyChangesToTemplate: @escaping () -> Void,
                             cancelChanges         : @escaping () -> Void,
                             isModified            : Bool,
                             isValid               : Bool = true) -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .automatic) {
                TemplateButton(text   : "Modifier",
                               action : applyChangesToTemplate)
                Button(
                    action: cancelChanges,
                    label: {
                        HStack {
                            Image(systemName: "arrow.uturn.left")
                                .imageScale(.large)
                            Text("Revenir")
                        }
                    }
                )
                .capsuleButtonStyle()
                .disabled(!isModified || !isValid)
            }
        }
    }
}
