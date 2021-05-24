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
    var originalItem : Dossier
    @State private var dossierVM             = DossierViewModel()
    @State private var alertItem             : AlertItem?
    @State private var failedToCreateDossier : Bool   = false

    var toolBar: some View {
        /// Barre de titre
        HStack {
            Button(action: { self.presentationMode.wrappedValue.dismiss() },
                   label: { Text("Annuler") })
                .capsuleButtonStyle()

            Spacer()
            Text("Modifier...").font(.title).fontWeight(.bold)
            Spacer()

            Button(action: createDossier,
                   label: { Text("OK") })
                .capsuleButtonStyle()
                .disabled(!formIsValid())
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
        dossierVM.name = originalItem.name
        dossierVM.note = originalItem.note
    }

    /// Création du nouveau Dossier et ajout à la liste
    func createDossier() {
        do {
            try dataStore.createDossier(named       : dossierVM.name,
                                        annotatedBy : dossierVM.note)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la modification du dossier"),
                                       dismissButton : .default(Text("OK")))
            failedToCreateDossier = true
        }

        self.presentationMode.wrappedValue.dismiss()
    }

    /// Vérifie que la formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    func formIsValid() -> Bool {
        dossierVM.name.isNotEmpty
    }
}

struct DossierModifyView_Previews: PreviewProvider {
    static var previews: some View {
        DossierEditView(originalItem: Dossier())
    }
}
