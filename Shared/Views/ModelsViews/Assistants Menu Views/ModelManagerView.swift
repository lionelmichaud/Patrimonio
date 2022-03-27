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
import HelpersView

struct ModelManagerView: View {
    @EnvironmentObject private var dataStore : Store
    @EnvironmentObject private var model     : Model
    @State private var alertItem: AlertItem?
    private let repertoireTemplateNonTrouve = "Répertoire template non trouvé"
    
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
                                    .overlay(Label("Dossier Ouvert", systemImage: "folder.fill")
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
                            .overlay(Label(dataStore.activeDossier == nil ? "Tous les Dossiers" : "Autres Dossiers",
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
                    .overlay(Label("Dossier Patron", systemImage: "square.stack.3d.up.fill")
                                .font(.largeTitle))
            }
            .alert(item: $alertItem, content: newAlert)
            .padding()
            .navigationTitle("Transférer les Modèles")
            //.navigationBarTitleDisplayMode(.inline)
        }
    }

    /// La version du Model exportée est celle enregistrée sur disque.
    /// - Warning: les modifications non suavegardées ne seront pas exportées.
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
            self.alertItem = AlertItem(title         : Text((error as! DossierError).rawValue),
                                       dismissButton : .default(Text("OK")))
        }
        
        // partage des fichiers collectés
        let sideBarWidth = 230.0
        Patrimonio.share(items: urls, fromX: Double(geometry.size.width) + sideBarWidth, fromY: 32.0)
    }
    
    /// Le Model en mémoire est remplacé par celui issu du Template.
    /// Le Model enregistrée sur disque est remplacé par celui issu du Template
    private func copyFromTemplateToOpenDossier() {
        do {
            guard let templateFolder = PersistenceManager.templateFolder() else {
                throw FileError.failedToFindTemplateDirectory
            }
            guard let activeFolder = dataStore.activeDossier?.folder else {
                throw DossierError.failedToFindFolder
            }

            try model.loadFromJSON(fromFolder: templateFolder)
            try model.saveAsJSON(toFolder: activeFolder)
            self.alertItem = AlertItem(title         : Text("Copie réussie"),
                                       dismissButton : .default(Text("OK")))
        } catch FileError.failedToFindTemplateDirectory {
            self.alertItem = AlertItem(title         : Text("**Echec de la copie**").foregroundColor(.red) +
                                       Text("\n\(repertoireTemplateNonTrouve)"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("**Echec de la copie**").foregroundColor(.red),
                                       dismissButton : .default(Text("OK")))
        }
    }
    
    /// La version du Model exportée est celle en cours de modification.
    private func copyFromOpenDossierToTemplate() {
        do {
            guard let templateFolder = PersistenceManager.templateFolder() else {
                throw FileError.failedToFindTemplateDirectory
            }

            try model.saveAsJSON(toFolder: templateFolder)
            self.alertItem = AlertItem(title         : Text("Copie réussie"),
                                       dismissButton : .default(Text("OK")))
        } catch FileError.failedToFindTemplateDirectory {
            self.alertItem = AlertItem(title         : Text("**Echec de la copie**").foregroundColor(.red) +
                                       Text("\n\(repertoireTemplateNonTrouve)"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("**Echec de la copie**").foregroundColor(.red),
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
        } catch FileError.failedToFindTemplateDirectory {
            self.alertItem = AlertItem(title         : Text("**Echec de la copie**").foregroundColor(.red) +
                                       Text("\n\(repertoireTemplateNonTrouve)"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("**Echec de la copie**").foregroundColor(.red),
                                       dismissButton : .default(Text("OK")))
        }
    }
    
    /// La version du Model exportée est celle en cours de modification.
    private func copyFromOpenDossierToOtherDossiers() {
        do {
            guard let activeFolder = dataStore.activeDossier?.folder else {
                throw DossierError.failedToFindFolder
            }

            try PersistenceManager.forEachUserFolder { userFolder in
                if userFolder != activeFolder {
                    try model.saveAsJSON(toFolder: userFolder)
                }
            }
            
            self.alertItem = AlertItem(title         : Text("Copie réussie"),
                                       dismissButton : .default(Text("OK")))
        } catch {
            self.alertItem = AlertItem(title         : Text("**Echec de la copie**").foregroundColor(.red),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct ModelManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelManagerView()
    }
}
