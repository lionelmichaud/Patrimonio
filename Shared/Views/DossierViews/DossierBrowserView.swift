//
//  DossierBrowserView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI

struct DossierBrowserView: View {
    @EnvironmentObject var dataStore : Store
    @Binding var showingSheet        : Bool
    @State private var alertItem     : AlertItem?

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
                          icon : {
                            Image(systemName: "folder.fill.badge.person.crop")
                                .if(dossier.isActive) { $0.accentColor(.red) }
                    })
                }
                .isDetailLink(true)
            }
            .onDelete(perform: deleteDossier)
            .onMove(perform: moveDossier)
            .listStyle(SidebarListStyle())
        }
    }
    
    func activate(dossierIndex: Int) {
        dataStore.activate(dossierAtIndex: dossierIndex)
    }

    func deleteDossier(at offsets: IndexSet) {
        do {
            try dataStore.deleteDossier(atOffsets: offsets)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la suppression du dossier"),
                                       dismissButton : .default(Text("OK")))
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
                    .foregroundColor(.secondary)
                Spacer()
                Text(dossier.dateCreationStr)
            }
            .font(.caption)
            HStack {
                Text("Dernière modification")
                    .foregroundColor(.secondary)
                Spacer()
                Text(dossier.dateModificationStr)
            }
            .font(.caption)
        }
    }
}

struct DossierBrowserView_Previews: PreviewProvider {
    static let dataStore  = Store()

    static var previews: some View {
        NavigationView {
        List {
        DossierBrowserView(showingSheet: .constant(false))
            .environmentObject(dataStore)
        }
        }
    }
}
