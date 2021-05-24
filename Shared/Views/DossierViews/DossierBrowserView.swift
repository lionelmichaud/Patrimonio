//
//  DossierBrowserView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI

struct DossierBrowserView: View {
    @EnvironmentObject var dataStore         : Store
    @Binding var showingSheet                : Bool
    @State private var failedToDeleteDossier : Bool = false
    @State private var failedToLoadStore     : Bool = false
    @State private var alertItem             : AlertItem?

    var body: some View {
        // bouton "ajouter"
        Button(
            action: {
                withAnimation {
                    self.showingSheet = true
                }
            },
            label: {
                Label(title: { Text("Créer un nouveau dosssier") },
                      icon : { Image(systemName: "folder.fill.badge.plus") })
                    .foregroundColor(.accentColor)
            })

        Section(header: Text("Dossiers existants")) {
            // liste des dossiers
            ForEach(dataStore.dossiers) { dossier in
                NavigationLink(destination: DossierDetailView(dossier: dossier)) {
                    Label(title: { DossierRowView(dossier: dossier) },
                          icon : { Image(systemName: "folder.fill.badge.person.crop") })
                }
                .isDetailLink(true)
            }
            .onDelete(perform: deleteDossier)
            .onMove(perform: moveDossier)
            .listStyle(SidebarListStyle())
        }
        // charger la liste de dossier depuis le directory 'Documents'
        .onAppear(perform: onAppear)
    }

    func onAppear() {
        do {
            try dataStore.load()
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec du chargement des dossiers depuis votre espace personnel"),
                                       dismissButton : .default(Text("OK")))
            failedToLoadStore = true
        }
    }

    func deleteDossier(at offsets: IndexSet) {
        do {
            try dataStore.deleteDossier(atOffsets: offsets)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la suppression du dossier"),
                                       dismissButton : .default(Text("OK")))
            failedToDeleteDossier = true
        }
    }

    func moveDossier(from indexes: IndexSet, to destination: Int) {
        dataStore.dossiers.move(fromOffsets: indexes, toOffset: destination)
    }
}

struct DossierRowView : View {
    var dossier: Dossier

    var body: some View {
        VStack(alignment: .leading) {
            Text(dossier.name)
                .allowsTightening(true)
            HStack {
                Text("Date de création")
                    .font(.caption)
                Spacer()
                Text(dossier.dateCreationStr)
            }
            .font(.caption)
            HStack {
                Text("Dernière modification")
                Spacer()
                Text(dossier.dateModificationStr)
            }
            .font(.caption)
        }
    }
}

struct DossierBrowserView_Previews: PreviewProvider {
    static let dataStore  = Store()

    static func load() {
        try! dataStore.load()
    }

    static var previews: some View {
        DossiersView_Previews.load()
        return DossierBrowserView(showingSheet: .constant(false))
            .environmentObject(dataStore)
    }
}
