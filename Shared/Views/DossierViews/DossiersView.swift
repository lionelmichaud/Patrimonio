//
//  DossiersView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI

struct DossiersView: View {
    @EnvironmentObject var uiState   : UIState
    @EnvironmentObject var dataStore : Store
    @State var showingSheet = false

    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // entête
                DossierHeaderView()

                // liste des Dossiers
                DossierBrowserView(showingSheet: $showingSheet)
            }
            //.defaultSideBarListStyle()
            .listStyle(SidebarListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Dossiers")
            .toolbar {
                EditButton()
            }
            /// vue par défaut
            DossierHomeView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        // Vue modale de saisie d'un nouveau membre de la famille
        .sheet(isPresented: $showingSheet) {
            DossierAddView()
                .environmentObject(self.dataStore)
        }
    }
}

struct DossierHeaderView: View {
    var body: some View {
        NavigationLink(destination: DossierSummaryView()) {
            Text("Résumé").fontWeight(.bold)
        }
        .isDetailLink(true)
    }
}

struct DossiersView_Previews: PreviewProvider {
    static let uiState    = UIState()
    static let dataStore  = Store()

    static func load() {
        try! dataStore.load()
    }

    static var previews: some View {
        DossiersView_Previews.load()
        return DossiersView()
            .environmentObject(dataStore)
            .environmentObject(uiState)
            .colorScheme(.dark)
    }
}
