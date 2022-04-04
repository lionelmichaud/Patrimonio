//
//  DossierAddView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 20/05/2021.
//

import SwiftUI
import AppFoundation
import Persistence
import HelpersView

// MARK: - Création du nouveau DOSSIER

struct DossierAddView: View {
    @EnvironmentObject private var dataStore: Store
    @Environment(\.presentationMode) var presentationMode
    @State private var dossierVM             = DossierViewModel()
    @State private var alertItem             : AlertItem?
    @State private var failedToCreateDossier : Bool   = false

    var toolBar: some View {
        /// Barre de titre
        HStack {
            Button(action: { self.presentationMode.wrappedValue.dismiss() },
                   label: { Text("Annuler") })
                .buttonStyle(.bordered)

            Spacer()
            Text("Créer...").font(.title).fontWeight(.bold)
            Spacer()

            Button(action: createDossier,
                   label: { Text("OK") })
                .buttonStyle(.bordered)
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
    }

    /// Création du nouveau Dossier et ajout à la liste
    func createDossier() {
        do {
            try dataStore.createDossier(named       : dossierVM.name,
                                        annotatedBy : dossierVM.note)
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
        dossierVM.name.isNotEmpty
    }
}

struct DossierAddView_Previews: PreviewProvider {
    static var previews: some View {
        DossierAddView()
    }
}
