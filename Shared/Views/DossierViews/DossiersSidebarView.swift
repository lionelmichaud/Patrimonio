//
//  DossiersView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI
import Persistence
import HelpersView

struct DossiersSidebarView: View {
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
            .listStyle(.sidebar)
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Dossiers")
            .toolbar { // de la sidebar
                EditButton()
            }
            /// vue par défaut
            NoLoadedDossierView()
        }
        .navigationViewStyle(.columns)
        // alerte si on a pas pu trouver le répertoire des dossiers
        .onAppear(perform: onAppear)
        .alert(item: $alertItem, content: newAlert)
        // Vue modale de saisie d'un nouveau membre de la famille
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
    static var previews: some View {
        TestEnvir.loadTestFilesFromTemplate()
        return TabView {
            DossiersSidebarView()
                .tabItem { Label("Dossiers", systemImage: "folder.fill.badge.person.crop") }
                .tag(UIState.Tab.expense)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.uiState)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.simulation)
        }
    }
}
