//
//  DossierDetailView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import SwiftUI

struct DossierDetailView: View {
    @EnvironmentObject private var dataStore: Store
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
    
    var dossierSection: some View {
        Section {
            Text(dossier.name).font(.headline)
            if dossier.note.isNotEmpty {
                Text(dossier.note).multilineTextAlignment(.leading)
            }
            LabeledText(label: "Date de céation",
                        text : dossier.dateCreationStr)
            LabeledText(label: "Date de dernière modification",
                        text : "\(dossier.dateModificationStr) à \(dossier.hourModificationStr)")
            LabeledText(label: "Nom du directory associé",
                        text : dossier.folderName)
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
                                  sectionHeader: "")
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .navigationTitle(Text("Dossier"))
        .navigationBarTitleDisplayModeInline()
        .alert(item: $alertItem, content: myAlert)
        .sheet(isPresented: $showingSheet) {
            DossierEditView(title        : "Modifier le Dossier",
                            originalItem : dossier)
                .environmentObject(self.dataStore)
        }
        .toolbar {
            // Bouton: Activer
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action : { activate(dossier) },
                    label  : { Image(systemName: "square.and.arrow.down") })
                    .disabled(dossier.isActive)
            }
            // Bouton: Dupliquer
            ToolbarItem(placement: .automatic) {
                Button(
                    action : duplicate,
                    label  : { Image(systemName: "doc.on.doc.fill") })
            }
            // Bouton: Modifier
            ToolbarItem(placement: .automatic) {
                Button(
                    action : {
                        withAnimation {
                            self.showingSheet = true
                        }
                    },
                    label  : { Image(systemName: "square.and.pencil") })
                    .disabled(changeOccured())
            }
       }
    }

    private func changeOccured() -> Bool {
        // TODO: - A compléter
        return false
    }

    private func activate(_ dossier: Dossier) {
        guard let dossierIndex = dataStore.dossiers.firstIndex(of: dossier) else {
            self.alertItem = AlertItem(title         : Text("Echec du chargement du Dossier"),
                                       dismissButton : .default(Text("OK")))
            return

        }
        dataStore.activate(dossierAtIndex: dossierIndex)
    }
    
    private func duplicate() {
        do {
            try dataStore.duplicate(dossier)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la duplication du dossier"),
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
