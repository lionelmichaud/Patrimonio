//
//  ModelManagerView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 15/02/2022.
//

import SwiftUI
import Files
import Persistence
import ModelEnvironment

struct ModelManagerView: View {
    @EnvironmentObject private var dataStore : Store
    @State private var alertItem: AlertItem?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Vous pouvez transférer les modèles d'un endroit vers un autre en utilisant les flèches")
                if dataStore.activeDossier != nil {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.systemGray3))
                        .overlay(Label("iCloud", systemImage: "icloud.fill")
                                    .font(.largeTitle))
                }
                
                HStack {
                    if dataStore.activeDossier != nil {
                        HStack {
                            VStack {
                                Button(action: { shareFromOpenDossier(geometry: geometry) },
                                       label: {
                                        Image(systemName: "arrow.up")
                                            .font(Font.title.weight(.bold))
                                       })
                                    .padding()
                                    .foregroundColor(Color.white)
                                    .background(Color.blue)
                                    .cornerRadius(.infinity)
                                
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(UIColor.systemGray2))
                                    .overlay(Label("Dossier ouvert", systemImage: "folder.fill")
                                                .font(.largeTitle))
                                HStack {
                                    Button(action: copyFromTemplateToOpenDossier,
                                           label: {Image(systemName: "arrow.up")
                                            .font(Font.title.weight(.bold))
                                           })
                                        .padding()
                                        .foregroundColor(Color.white)
                                        .background(Color.blue)
                                        .cornerRadius(.infinity)
                                    Button(action: copyFromOpenDossierToTemplate,
                                           label: {Image(systemName: "arrow.down")
                                            .font(Font.title.weight(.bold))
                                           })
                                        .padding()
                                        .foregroundColor(Color.white)
                                        .background(Color.blue)
                                        .cornerRadius(.infinity)
                                }
                            }
                            
                            Button(action: copyFromOpenDossierToOtherDossiers,
                                   label: {
                                    Image(systemName: "arrow.right")
                                        .font(Font.title.weight(.bold))
                                   })
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.blue)
                                .cornerRadius(.infinity)
                        }
                    }
                    
                    VStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(UIColor.systemGray2))
                            .padding(.top)
                            .overlay(Label(dataStore.activeDossier == nil ? "Dossiers" : "Autres dossiers",
                                           systemImage: "folder.fill")
                                        .font(.largeTitle))
                        
                        Button(action: copyFromTemplateToOtherDossiers,
                               label: {
                                Image(systemName: "arrow.up")
                                    .font(Font.title.weight(.bold))
                               })
                            .padding()
                            .foregroundColor(Color.white)
                            .background(Color.blue)
                            .cornerRadius(.infinity)
                    }
                }
                
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.systemGray))
                    .overlay(Label("Patron", systemImage: "square.stack.3d.up.fill")
                                .font(.largeTitle))
            }
            .alert(item: $alertItem, content: newAlert)
            .padding()
            .navigationTitle("Transférer les Modèles")
            //.navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func shareFromOpenDossier(geometry: GeometryProxy) {
        // collecte des URL des fichiers modèle JSON
        var urls = [URL]()
        do {
            guard let activeFolder = dataStore.activeDossier?.folder else {
                throw DossierError.failedToFindFolder
            }
            activeFolder.files.forEach { file in
                if let ext = file.extension, ext == "json" {
                    if file.name.contains("ModelConfig") {
                        urls.append(file.url)
                    }
                }
            }
            
        } catch {
            self.alertItem = AlertItem(title         : Text("Le partage a échoué"),
                                       dismissButton : .default(Text("OK")))
        }
        
        // partage des fichiers collectés
        let sideBarWidth = 230.0
        Patrimonio.share(items: urls, fromX: Double(geometry.size.width) + sideBarWidth, fromY: 32.0)
    }
    
    private func copyFromTemplateToOpenDossier() {
        do {
            guard let templateFolder = PersistenceManager.templateFolder() else {
                throw FileError.failedToFindTemplateDirectory
            }
            guard let activeFolder = dataStore.activeDossier?.folder else {
                throw DossierError.failedToFindFolder
            }
            
            let model = Model()
            try model.loadFromJSON(fromFolder: templateFolder)
            try model.saveAsJSON(toFolder: activeFolder)
            self.alertItem = AlertItem(title         : Text("Copie réussie"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la copie"),
                                       dismissButton : .default(Text("OK")))
        }
    }
    
    private func copyFromOpenDossierToTemplate() {
        do {
            guard let templateFolder = PersistenceManager.templateFolder() else {
                throw FileError.failedToFindTemplateDirectory
            }
            guard let activeFolder = dataStore.activeDossier?.folder else {
                throw DossierError.failedToFindFolder
            }
            
            let model = Model()
            try model.loadFromJSON(fromFolder: activeFolder)
            try model.saveAsJSON(toFolder: templateFolder)
            self.alertItem = AlertItem(title         : Text("Copie réussie"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la copie"),
                                       dismissButton : .default(Text("OK")))
        }
    }
    
    private func copyFromTemplateToOtherDossiers() {
        do {
            guard let templateFolder = PersistenceManager.templateFolder() else {
                throw FileError.failedToFindTemplateDirectory
            }
            let activeFolder = dataStore.activeDossier?.folder
            
            let model = Model()
            try model.loadFromJSON(fromFolder: templateFolder)
            
            try PersistenceManager.forEachUserFolder { userFolder in
                if !(activeFolder != nil && userFolder == activeFolder) {
                    try model.saveAsJSON(toFolder: userFolder)
                }
            }
            
            self.alertItem = AlertItem(title         : Text("Copie réussie"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la copie"),
                                       dismissButton : .default(Text("OK")))
        }
    }
    
    private func copyFromOpenDossierToOtherDossiers() {
        do {
            guard let activeFolder = dataStore.activeDossier?.folder else {
                throw DossierError.failedToFindFolder
            }
            
            let model = Model()
            try model.loadFromJSON(fromFolder: activeFolder)
            
            try PersistenceManager.forEachUserFolder { userFolder in
                if userFolder != activeFolder {
                    try model.saveAsJSON(toFolder: userFolder)
                }
            }
            
            self.alertItem = AlertItem(title         : Text("Copie réussie"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la copie"),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct ModelManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelManagerView()
    }
}
