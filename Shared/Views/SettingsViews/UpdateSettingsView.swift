//
//  UpdateSettingsView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 08/12/2021.
//

import SwiftUI
import Persistence
import ModelEnvironment

struct UpdateSettingsView: View {
    @State private var alertItem: AlertItem?
    
    var body: some View {
        Form {
            Section(header:
                        Text("Remplacer votre patron par la version par défaut fournie par l'application")
                        .textCase(.none)) {
                Button(action: updateTemplateDirectoryFromApp,
                       label: { Text("Remplacer tout") })
                Button(action: updateModelFilesFromApp,
                       label: { Text("Remplacer seulement le modèle environemental") })
            }
            .alert(item: $alertItem, content: createAlert)
        }
        .navigationTitle(Text("Mise à Jour"))

    }
    
    private func updateTemplateDirectoryFromApp() {
        do {
            try PersistenceManager.forcedImportAllTemplateFilesFromApp()
            self.alertItem = AlertItem(title         : Text("Mise à jour réussie"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la mise à jour"),
                                       dismissButton : .default(Text("OK")))
        }
    }

    private func updateModelFilesFromApp() {
        do {
            guard let templateFolder = PersistenceManager.templateFolder() else {
                throw FileError.failedToFindTemplateDirectory
            }
            
            try PersistenceManager.duplicateFilesFromApp(toFolder: templateFolder) { fromFolder, toFolder in
                let model = Model()
                try model.loadFromJSON(fromFolder: fromFolder)
                try model.saveAsJSON(toFolder: toFolder)
                self.alertItem = AlertItem(title         : Text("Mise à jour réussie"),
                                           dismissButton : .default(Text("OK")))
            }
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
