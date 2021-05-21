//
//  DossierAddView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 20/05/2021.
//

import SwiftUI
import AppFoundation

// MARK: - Création du nouveau DOSSIER

struct DossierAddView: View {
    @EnvironmentObject private var dataStore: Store
    @Environment(\.presentationMode) var presentationMode
    @State private var alertItem             : AlertItem?
    @State private var action                : DossierCreationActionEnum = .new
    @State private var name                  : String                    = Date.now.stringShortDate
    @State private var note                  : String                    = ""
    @State private var failedToCreateDossier : Bool                      = false

    var toolBar: some View {
        /// Barre de titre
        HStack {
            Button(action: { self.presentationMode.wrappedValue.dismiss() },
                   label: { Text("Annuler") })
                .capsuleButtonStyle()

            Spacer()
            Text("Créer...").font(.title).fontWeight(.bold)
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
                    CasePicker(pickedCase: $action, label: "Créer")
                        .pickerStyle(SegmentedPickerStyle())
                    switch action {
                        case .new:
                            VStack {
                                HStack {
                                    Text("Nom")
                                        .frame(width: 70, alignment: .leading)
                                    TextField(Date.now.stringShortDate, text: $name)
                                }
                                LabeledTextEditor(label: "Note", text: $note)
                            }
                        case .copy:
                            EmptyView()
                    }
                }
            }
            .font(.body)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .alert(item: $alertItem, content: myAlert)
        }
    }

    /// Création du nouveau Dossier et ajout à la liste
    func createDossier() {
        do {
            try dataStore.addDossier(named       : name,
                                     annotatedBy : note,
                                     action      : action)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la création du dossier"),
                                       dismissButton : .default(Text("OK")))
            failedToCreateDossier = true
        }

        self.presentationMode.wrappedValue.dismiss()
    }

    /// Vérifie que la formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    func formIsValid() -> Bool {
        name.isNotEmpty
    }
}

struct DossierAddView_Previews: PreviewProvider {
    static var previews: some View {
        DossierAddView()
    }
}
