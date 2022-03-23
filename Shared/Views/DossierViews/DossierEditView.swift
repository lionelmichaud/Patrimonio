//
//  DossierModifyView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/05/2021.
//

import SwiftUI
import AppFoundation
import Persistence
import HelpersView

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
                            TextField(CalendarCst.now.stringShortDate, text: $dossierVM.name)
                        }
                        LabeledTextEditor(label: "Note", text: $dossierVM.note)
                    }
                }
            }
            .font(.body)
            .textFieldStyle(.roundedBorder)
            .alert(item: $alertItem, content: newAlert)
        }
        .onAppear(perform: onAppear)
    }

    private func onAppear() {
        dossierVM = DossierViewModel(from: originalItem)
    }
    
    /// L'utilisateur a cliqué sur OK
    private func commit() {
        if let originalItem = originalItem {
            // on était en cours de modification et non de création de Dossier
            let modifiedItem = dossierVM.copyFromViewModel(original: originalItem)
            if modifiedItem != originalItem {
                // on a modifié un item existant
                updateItem(with: modifiedItem)
            } else {
                self.presentationMode.wrappedValue.dismiss()
            }
        } else {
            // on créé un nouvel item
            createItem()
        }
    }

    /// Création du nouveau Dossier et ajout à la liste
    private func createItem() {
        do {
            try dataStore.createDossier(named       : dossierVM.name,
                                        annotatedBy : dossierVM.note)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la création du dossier"),
                                       dismissButton : .default(Text("OK")))
        }

        self.presentationMode.wrappedValue.dismiss()
    }
    
    /// Modification d'un dossier existant. L'utilisateur a réellement modifié quelque chose.
    /// - Parameter modifiedItem: nouvelle valeur du dosser
    private func updateItem(with modifiedItem: Dossier) {
        if let idx = dataStore.dossiers.firstIndex(where: {$0 == originalItem}) {
            do {
                try modifiedItem.saveAsJSON()
            } catch {
                self.alertItem = AlertItem(title         : Text("Echec de la modification du dossier"),
                                           dismissButton : .default(Text("OK")))
            }
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
