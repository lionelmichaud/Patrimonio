//
//  DebtSidebarView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 31/03/2022.
//

import SwiftUI
import AppFoundation
import Liabilities
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct DebtSidebarView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    private let indentLevel = 1
    private let label       = "Dette"
    private let iconAdd     = Image(systemName : "plus.circle.fill")
    private let icon€       = Image(systemName   : "eurosign.circle.fill")

    var body: some View {
        DisclosureGroup {
            // ajout d'un nouvel item à la liste
            Button(
                action: addItem,
                label: {
                    Label(title: { Text("Ajouter un élément...") },
                          icon : { iconAdd.imageScale(.large) })
                })

            // liste des items
            ForEach($patrimoine.liabilities.debts.items) { $item in
                NavigationLink(destination: DebtDetailedView(updateDependenciesToModel: resetSimulation,
                                                             item: $item.transaction())) {
                    LabeledValueRowView2(label       : item.name,
                                         value       : item.value(atEndOf: CalendarCst.thisYear),
                                         indentLevel : 3,
                                         header      : false,
                                         iconItem    : icon€)
                    .modelChangesSwipeActions(duplicateItem : { duplicateItem(item) },
                                              deleteItem    : { deleteItem(item) })

                }.isDetailLink(true)
            }
            .onDelete(perform: removeItems)
            .onMove(perform: move)
            //}
        } label: {
            LabeledValueRowView2(label       : label,
                                 value       : patrimoine.liabilities.debts.value(atEndOf: CalendarCst.thisYear),
                                 indentLevel : indentLevel,
                                 header      : true,
                                 iconItem    : icon€)
        }
        .listRowInsets(EdgeInsets(top: 0, leading: ListTheme[indentLevel].indent, bottom: 0, trailing: 0))
#if os(macOS)
        .collapsible(true)
#endif
    }

    /// actualiser toutes les dépendances au Model
    private func resetSimulation() {
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()
    }

    func addItem() {
        // ajouter un nouvel item à la liste
        let newItem = Debt(name: "Nouvel élément",
                           delegateForAgeOf: family.ageOf)
        patrimoine.liabilities.debts.add(newItem)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func duplicateItem(_ item: Debt) {
        var newItem = item
        // générer un nouvel identifiant pour la copie
        newItem.id = UUID()
        newItem.name += "-copie"
        // duppliquer l'item de la liste
        patrimoine.liabilities.debts.add(newItem)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func deleteItem(_ item: Debt) {
        // supprimer l'item de la liste
        patrimoine.liabilities.debts.delete(item)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func removeItems(at offsets: IndexSet) {
        patrimoine.liabilities.debts.delete(at: offsets)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func move(from source: IndexSet, to destination: Int) {
        patrimoine.liabilities.debts.move(from: source, to: destination)
    }
}
