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
    func modelChangesToolbar2<Value: Equatable>(
        subModel                  : Transac<Value>,
        isValid                   : Bool = true,
        updateDependenciesToModel : @escaping () -> Void) -> some View {
        self.toolbar {
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
