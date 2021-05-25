//
//  DossierModifyView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/05/2021.
//

import SwiftUI

struct DossierEditView: View {
    @EnvironmentObject private var dataStore: Store
    @Environment(\.presentationMode) var presentationMode
    var title        : String
    var originalItem : Dossier?
    @State private var dossierVM = DossierViewModel()
    @State private var alertItem : AlertItem?

    var toolBar: some View {
        /// Barre de titre
        HStack {
            Button(action: { self.presentationMode.wrappedValue.dismiss() },
                   label: { Text("Annuler") })
                .capsuleButtonStyle()

            Spacer()
            Text(title).font(.title).fontWeight(.bold)
            Spacer()

            Button(action: commit,
                   label: { Text("OK") })
                .capsuleButtonStyle()
                .disabled(!dossierVM.isValid())
        }
        .padding(.horizontal)
        .padding(.top)
    }

    var body: some View {
        VStack {
            /// Barre de titre
            toolBar

            /// Formulaire
            Form {
                Section {
                    VStack {
                        HStack {
                            Text("Nom")
                                .frame(width: 70, alignment: .leading)
                            TextField(Date.now.stringShortDate, text: $dossierVM.name)
                        }
                        LabeledTextEditor(label: "Note", text: $dossierVM.note)
                    }
                }
            }
            .font(.body)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .alert(item: $alertItem, content: myAlert)
        }
        .onAppear(perform: onAppear)
    }

    func onAppear() {
        dossierVM = DossierViewModel(from: originalItem)
    }

    func commit() {
        if let originalItem = originalItem {
            // on a modifié un item existant
            let modifiedItem = dossierVM.copyFromViewModel(original: originalItem)
            if modifiedItem != originalItem {
                updateItem(with: modifiedItem)
            }
        } else {
            // on créé un nouvel item
            createItem()
        }
    }

    /// Création du nouveau Dossier et ajout à la liste
    func createItem() {
        do {
            try dataStore.createDossier(named       : dossierVM.name,
                                        annotatedBy : dossierVM.note)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la création du dossier"),
                                       dismissButton : .default(Text("OK")))
        }

        self.presentationMode.wrappedValue.dismiss()
    }
    
    func updateItem(with modifiedItem: Dossier) {
        if let idx = dataStore.dossiers.firstIndex(where: {$0 == originalItem}) {
            dataStore.dossiers[idx] = modifiedItem
        } else {
            self.alertItem = AlertItem(title         : Text("Echec de la modification du dossier"),
                                       dismissButton : .default(Text("OK")))
        }
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct DossierModifyView_Previews: PreviewProvider {
    static var dossier = Dossier()
        .namedAs("Dossier test")
        .annotatedBy("Note test")
        .createdOn()
        .ownedByUser()
    
    static var previews: some View {
        Group {
            DossierEditView(title: "Test Modifier", originalItem: dossier)
            DossierEditView(title: "Test Créer")
        }
    }
}
