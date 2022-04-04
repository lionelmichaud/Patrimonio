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
        Section {
            ForEach(dataStore.dossiers) { dossier in
                NavigationLink(destination: DossierDetailView(dossier: dossier)) {
                    Label(title: { DossierRowView(dossier: dossier) },
                          icon : {
                            Image(systemName: "folder.fill.badge.person.crop")
                                .if(dossier.isActive) {
                                    $0.foregroundColor(savable(dossier) ? .red : .green)
                                }
                    })
                    .modelChangesSwipeActions(duplicateItem : { duplicate(dossier) },
                                              deleteItem    : { delete(dossier) })
                }
                .isDetailLink(true)
            }
            .onDelete(perform: deleteDossier)
            .onMove(perform: moveDossier)
        } header: {
            Text("Dossiers existants")
        }
        .alert(item: $alertItem, content: newAlert)
    }

    /// Dupliquer le Dossier sélectionné
    private func duplicate(_ dossier: Dossier) {
        guard !savable(dossier) else {
            self.alertItem = AlertItem(title         : Text("Attention"),
                                       message       : Text("Toutes les modifications sur le dossier ouvert seront perdues"),
                                       primaryButton : .default(Text("Continuer"),
                                                                action: {
                do {
                    try dataStore.duplicate(dossier)
                } catch {
                    DispatchQueue.main.async {
                        self.alertItem = AlertItem(title         : Text("Echec de la duplication du dossier !"),
                                                   dismissButton : .default(Text("OK")))
                    }
                }
            }),
                                       secondaryButton: .cancel())
            return
        }

        do {
            try dataStore.duplicate(dossier)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la duplication du dossier !"),
                                       dismissButton : .default(Text("OK")))
        }
    }

    func delete(_ dossier: Dossier) {
        alertItem =
        AlertItem(title         : Text("Attention").foregroundColor(.red),
                  message       : Text("La destruction du dossier est irréversible"),
                  primaryButton : .destructive(Text("Supprimer"),
                                               action: {
            /// insert alert 1 action here
            do {
                try dataStore.delete(dossier)
            } catch {
                DispatchQueue.main.async {
                    alertItem = AlertItem(title         : Text("Echec de la suppression du dossier"),
                                          dismissButton : .default(Text("OK")))
                }
            }
        }),
                  secondaryButton: .cancel())
    }

    private func deleteDossier(at offsets: IndexSet) {
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
    
    private func moveDossier(from indexes: IndexSet, to destination: Int) {
        dataStore.dossiers.move(fromOffsets: indexes, toOffset: destination)
    }

    /// True si le dossier est actif et a été modifié
    private func savable(_ dossier: Dossier) -> Bool {
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
