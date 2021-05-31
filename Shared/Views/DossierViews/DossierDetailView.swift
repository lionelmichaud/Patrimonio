//
//  DossierDetailView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import SwiftUI

struct DossierDetailView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    var dossier: Dossier
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false
    
    var activeSection: some View {
        Section {
            Label(
                title: {
                    Text("Dossier en cours d'utilisation")
                        .font(.headline)
                },
                icon : {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.red)
                        .font(.title)
                })
        }
    }
    
    var body: some View {
        Form {
            // indicateur de chargement du Dossier
            if dossier.isActive {
                activeSection
            }
            // affichage du Dossier
            DossierPropertiesView(dossier: dossier,
                                  sectionHeader: "Descriptif du Dossier")
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .navigationTitle(Text("Dossier"))
        //.navigationBarTitleDisplayModeInline()
        .alert(item: $alertItem, content: myAlert)
        .sheet(isPresented: $showingSheet) {
            DossierEditView(title        : "Modifier le Dossier",
                            originalItem : dossier)
                .environmentObject(self.dataStore)
        }
        .toolbar {
            /// Bouton: Charger
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action : activate,
                    label  : {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .imageScale(.large)
                            Text("Charger")
                        }
                    })
                    .capsuleButtonStyle()
                    .disabled(dossier.isActive)
            }
            /// Bouton: Dupliquer
            ToolbarItem(placement: .automatic) {
                Button(
                    action : duplicate,
                    label  : {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                                .imageScale(.medium)
                            Text("Dupliquer")
                        }
                    })
                    .capsuleButtonStyle()
                    //.disabled(patrimoine.isModified)
            }
            /// Bouton: Modifier
            ToolbarItem(placement: .automatic) {
                Button(
                    action : {
                        withAnimation {
                            self.showingSheet = true
                        }
                    },
                    label  : {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .imageScale(.large)
                            Text("Modifier")
                        }
                    })
                    .capsuleButtonStyle()
                    .disabled(!dossier.isActive)
            }
       }
    }

    private func changeOccured() -> Bool {
        // TODO: - A compléter
        return false
    }
    
    /// Rendre le Dossier sélectionné actif et charger ses données dans le modèle
    private func activate() {
        guard let dossierIndex = dataStore.dossiers.firstIndex(of: dossier) else {
            self.alertItem = AlertItem(title         : Text("Impossible de trouver le Dossier !"),
                                       dismissButton : .default(Text("OK")))
            return

        }
        
        // vérifier l'existence du Folder associé au Dossier
        guard let folder = dossier.folder else {
            self.alertItem = AlertItem(title         : Text("Impossible de trouver le Dossier !"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        
        // charger les données utilisateur depuis le Dossier
        do {
            try patrimoine.loadFromJSON(fromFolder: folder)
            try family.loadFromJSON(fromFolder: folder)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de chargement du contenu du dossier !"),
                                       dismissButton : .default(Text("OK")))
        }

        // rendre le Dossier actif seulement si tout c'est bien passé
        dataStore.activate(dossierAtIndex: dossierIndex)
    }
    
    /// Dupliquer le Dossier sélectionné
    private func duplicate() {
        do {
            try dataStore.duplicate(dossier)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la duplication du dossier !"),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct DossierDetailView_Previews: PreviewProvider {
    static let dossier = Dossier()
        .namedAs("Nom du dossier")
        .annotatedBy("note ligne 1\nligne 2")
        .createdOn(Date.now)
        .activated()
    
    static var previews: some View {
        DossierDetailView(dossier: dossier)
            .previewLayout(.sizeThatFits)
    }
}
