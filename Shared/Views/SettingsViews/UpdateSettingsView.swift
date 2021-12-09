//
//  UpdateSettingsView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 08/12/2021.
//

import SwiftUI
import Persistence

struct UpdateSettingsView: View {
    @State private var alertItem: AlertItem?

    var body: some View {
        Button(action: updateTemplateDirectory,
               label: {
                Text("Mettre à jour les modèles")
               })
            .capsuleButtonStyle()
            .alert(item: $alertItem, content: createAlert)
    }
    
    func updateTemplateDirectory() {
        do {
            try PersistenceManager.forcedImportTemplatesFromApp()
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la mise à jour"),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct UpdateSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateSettingsView()
    }
}
