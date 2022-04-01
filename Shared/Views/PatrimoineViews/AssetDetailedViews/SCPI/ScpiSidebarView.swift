//
//  ScpiSidebarView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 01/04/2022.
//

import SwiftUI
import AppFoundation
import AssetsModel
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct ScpiSidebarView: View {
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    private let indentLevel = 2
    private let label       = "SCPI"
    private let iconAdd     = Image(systemName : "plus.circle.fill")
    private let icon€       = Image(systemName   : "building.2.crop.circle")

    private var totalSCPI: Double {
        patrimoine.assets.scpis.value(atEndOf: CalendarCst.thisYear)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandSCPI) {
            // ajout d'un nouvel item à la liste
            Button(
                action: addItem,
                label: {
                    Label(title: { Text("Ajouter un élément...") },
                          icon : { iconAdd.imageScale(.large) })
                })

            // liste des items
            ForEach($patrimoine.assets.scpis.items) { $item in
                NavigationLink(destination: ScpiDetailedView(updateDependenciesToModel: resetSimulation,
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
        } label: {
            LabeledValueRowView2(label       : label,
                                 value       : totalSCPI,
                                 indentLevel : indentLevel,
                                 header      : true,
                                 iconItem    : icon€)
        }
        //.listRowInsets(EdgeInsets(top: 0, leading: ListTheme[indentLevel].indent, bottom: 0, trailing: 0))
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
        let newItem = SCPI(name: "Nouvel élément",
                           delegateForAgeOf: family.ageOf)
        patrimoine.assets.scpis.add(newItem)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func duplicateItem(_ item: SCPI) {
        var newItem = item
        // générer un nouvel identifiant pour la copie
        newItem.id = UUID()
        newItem.name += "-copie"
        // duppliquer l'item de la liste
        patrimoine.assets.scpis.add(newItem)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func deleteItem(_ item: SCPI) {
        // supprimer l'item de la liste
        patrimoine.assets.scpis.delete(item)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func removeItems(at offsets: IndexSet) {
        patrimoine.assets.scpis.delete(at: offsets)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.scpis.move(from: source, to: destination)
    }
}
