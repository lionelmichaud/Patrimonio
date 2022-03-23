//
//  DossierBrowserView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI
import Persistence
import ModelEnvironment
import LifeExpense
import PatrimoineModel
import FamilyModel
import HelpersView
import SimulationAndVisitors

struct DossierBrowserView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    @Binding var showingSheet    : Bool
    @State private var alertItem : AlertItem?

    var body: some View {
        /// bouton "ajouter"
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

        /// liste des dossiers
        Section(header: Text("Dossiers existants")) {
            ForEach(dataStore.dossiers) { dossier in
                NavigationLink(destination: DossierDetailView(dossier: dossier)) {
                    Label(title: { DossierRowView(dossier: dossier) },
                          icon : {
                            Image(systemName: "folder.fill.badge.person.crop")
                                .if(dossier.isActive) { $0.accentColor(savable(dossier) ? .red : .green) }
                    })
                }
                .isDetailLink(true)
            }
            .onDelete(perform: deleteDossier)
            .onMove(perform: moveDossier)
        }
        .alert(item: $alertItem, content: newAlert)
    }
    
    func deleteDossier(at offsets: IndexSet) {
        alertItem =
        AlertItem(title         : Text("Attention").foregroundColor(.red),
                  message       : Text("La destruction du dossier est irréversible"),
                  primaryButton : .destructive(Text("Supprimer"),
                                               action: {
            /// insert alert 1 action here
            do {
                try dataStore.deleteDossier(atOffsets: offsets)
            } catch {
                DispatchQueue.main.async {
                    alertItem = AlertItem(title         : Text("Echec de la suppression du dossier"),
                                          dismissButton : .default(Text("OK")))
                }
            }
        }),
                  secondaryButton: .cancel())
    }
    
    func moveDossier(from indexes: IndexSet, to destination: Int) {
        dataStore.dossiers.move(fromOffsets: indexes, toOffset: destination)
    }

    /// True si le dossier est actif et a été modifié
    func savable(_ dossier: Dossier) -> Bool {
        dossier.isActive &&
            (family.isModified ||
                expenses.isModified ||
                patrimoine.isModified ||
                model.isModified ||
                simulation.isModified)
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
