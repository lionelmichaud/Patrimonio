//
//  ModelUpdateToolbar.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 27/03/2022.
//

import SwiftUI
import AppFoundation

// MARK: - View Extensions

extension View {

    /// ViewModifier qui afiche une bare de boutons dans la NavigationView
    /// comportant deux boutons: `rollback`et `commit'
    ///
    /// Le bouton `rollback`:
    ///  - annule toute modification réalisée.
    ///  - Le `subModel` garde sa valeur avant modifications réalisées dans la vue.
    ///
    /// Le bouton `commit`:
    ///  - n'apparaît que si `isValid` est Vrai.
    ///  - Il permet d'appliquer effictivement les modifications réalisées au Bnding de l'objet.
    ///  - Le `subModel` prend sa valeur modifiée dans la vue.
    ///
    /// - Parameters:
    ///   - subModel: le Binding sur un objet modifiable.
    ///   - isValid: Vrai si l'objet modifié est valide.
    ///   - updateDependenciesToModel: Une closure qui met à jour toutes les dépendances à l'objet modifié.
    ///
    func modelChangesToolbar<Value: Equatable>(
        subModel                  : Transac<Value>,
        isValid                   : Bool = true,
        updateDependenciesToModel : @escaping () -> Void) -> some View {
            self.toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // revenir à la version du modèle en mémoire avant les modifications faites localement
                    Button(
                        action: subModel.rollback,
                        label: {
                            Image(systemName: "arrow.uturn.left")
                                .imageScale(.large)
                        }
                    )
                    .buttonStyle(.bordered)
                    .disabled(!subModel.hasChanges)

                    // valider les modifications locales en appliquant au modèle en mémoire
                    Button(
                        action: {
                            subModel.commit()
                            updateDependenciesToModel()
                        },
                        label: {
                            Image(systemName: "checkmark")
                                .imageScale(.large)
                        }
                    )
                    .buttonStyle(.bordered)
                    .disabled(!subModel.hasChanges || !isValid)
                }
            }
        }

    func modelChangesSwipeActions(duplicateItem : @escaping () -> Void,
                                  deleteItem    : @escaping () -> Void) -> some View {
        // duppliquer l'item
        self.swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                duplicateItem()
            } label: {
                Label("Duppliquer", systemImage: "doc.on.doc")
            }
            .tint(.indigo)
        }
        // supprimer l'item
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.linear(duration: 0.4)) {
                    deleteItem()
                }
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        }
    }
}
