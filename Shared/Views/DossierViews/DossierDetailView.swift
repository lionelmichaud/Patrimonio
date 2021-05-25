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

    var body: some View {
        Form {
            Text(dossier.name).font(.headline)
            Text(dossier.note).multilineTextAlignment(.leading)
            LabeledText(label: "Date de céation",
                        text : dossier.dateCreationStr)
            LabeledText(label: "Date de dernière modification",
                        text : "\(dossier.dateModificationStr) à \(dossier.hourModificationStr)")
            LabeledText(label: "Nom du directory associé",
                        text : dossier.folderName)
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
            ToolbarItem(placement: .automatic) {
                Button(
                    action : duplicate,
                    label  : { Text("Dupliquer") })
                    .disabled(changeOccured())
            }
            ToolbarItem(placement: .automatic) {
                Button(
                    action : {
                        withAnimation {
                            self.showingSheet = true
                        }
                    },
                    label  : { Text("Modifier") })
                    .disabled(changeOccured())
            }
       }
    }

    private func changeOccured() -> Bool {
        return false
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
    static var previews: some View {
        DossierDetailView(dossier: dossier)
            .previewLayout(.sizeThatFits)
    }
}
