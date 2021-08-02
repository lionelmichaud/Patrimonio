//
//  DossiersView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI
import Persistence

struct DossiersView: View {
    @EnvironmentObject var uiState   : UIState
    @EnvironmentObject var dataStore : Store
    @State private var alertItem     : AlertItem?
    @State private var showingSheet  = false

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
            NoLoadedDossierView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        // Vue modale de saisie d'un nouveau membre de la famille
        .onAppear(perform: onAppear)
        .alert(item: $alertItem, content: myAlert)
        .sheet(isPresented: $showingSheet) {
            DossierEditView(title: "Créer un nouveau dossier")
                .environmentObject(self.dataStore)
       }
    }

    func onAppear() {
        if dataStore.failedToLoadDossiers {
            self.alertItem = AlertItem(title         : Text("Echec du chargement des dossiers"),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct DossierHeaderView: View {
    var body: some View {
        NavigationLink(destination: DossierSummaryView()) {
            Text("Dossier en cours d'utilisation")
        }
        .isDetailLink(true)
    }
}

struct DossiersView_Previews: PreviewProvider {
    static let uiState    = UIState()
    static let dataStore  = Store()

    static var previews: some View {
        DossiersView()
            .environmentObject(dataStore)
            .environmentObject(uiState)
            .colorScheme(.dark)
    }
}
