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
                            if dossier.isActive {
                                Image(systemName: "arrowshape.turn.up.backward")
                                    .imageScale(.large)
                                Text("Revenir")

                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .imageScale(.large)
                                Text("Charger")

                            }
                        }
                    })
                    .capsuleButtonStyle()
                    .disabled(!activable())
            }
            /// Bouton: Sauvegarder
            ToolbarItem(placement: .automatic) {
                Button(
                    action : { save(dossier) },
                    label  : {
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .imageScale(.large)
                            Text("Enregistrer")
                        }
                    })
                    .capsuleButtonStyle()
                    .disabled(!savable())
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

    /// True si le dossier est inactif ou s'il est actif et à été modifié
    private func activable() -> Bool {
        !dossier.isActive || savable()
    }
    
    /// True si le dossier est actif et à été modifié
    private func savable() -> Bool {
        dossier.isActive && (family.isModified || patrimoine.isModified)
    }

    /// Enregistrer les données utilisateur dans le Dossier sélectionné actif
    private func save(_ dossier: Dossier) {
        // vérifier l'existence du Folder associé au Dossier
        guard let folder = dossier.folder else {
            self.alertItem = AlertItem(title         : Text("Impossible de trouver le Dossier !"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        // enregistrer le desscripteur du Dossier
        do {
            try dossier.saveAsJSON()
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de l'enregistrement du dossier"),
                                       dismissButton : .default(Text("OK")))
        }

        // enregistrer les données utilisateur depuis le Dossier
        do {
            try family.saveAsJSON(toFolder: folder)
            try patrimoine.saveAsJSON(toFolder: folder)
            Simulation.playSound()
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de l'enregistrement du contenu du dossier !"),
                                       dismissButton : .default(Text("OK")))
        }
    }

    /// si le dossier est déjà actif et a été modifié alors prévenir que les modif vont être écrasées
    private func activate() {
        if dossier.isActive {
        self.alertItem = AlertItem(title         : Text("Attention").foregroundColor(.red),
                                   message       : Text("Toutes les modifications seront perdues"),
                                   primaryButton : .destructive(Text("Revenir"),
                                                                action: load),
                                   secondaryButton: .cancel())
        } else {
            load()
        }
    }

    /// Rendre le Dossier sélectionné actif et charger ses données dans le modèle
    private func load() {
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
