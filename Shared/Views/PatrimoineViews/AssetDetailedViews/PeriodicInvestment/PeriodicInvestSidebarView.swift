//
//  PeriodicInvestSidebarView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/04/2022.
//

import SwiftUI
import AppFoundation
import AssetsModel
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct PeriodicInvestSidebarView: View {
    @EnvironmentObject var uiState    : UIState
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    let simulationReseter: CanResetSimulationP
    private let indentLevel = 2
    private let label       = "Investissement Périodique"
    private let iconAdd     = Image(systemName : "plus.circle.fill")
    private let icon€       = Image(systemName   : "eurosign.circle.fill")

    private var total: Double {
        patrimoine.assets.periodicInvests.value(atEndOf: CalendarCst.thisYear)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandPeriodic) {
            // ajout d'un nouvel item à la liste
            Button(
                action: addItem,
                label: {
                    Label(title: { Text("Ajouter un élément...") },
                          icon : { iconAdd.imageScale(.large) })
                })

            // liste des items
            ForEach($patrimoine.assets.periodicInvests.items) { $item in
                NavigationLink(destination: PeriodicInvestDetailedView(updateDependenciesToModel: resetSimulation,
                                                                       item: $item.transaction())) {
                    LabeledValueRowView(label       : item.name,
                                         value       : item.value(atEndOf: CalendarCst.thisYear),
                                         indentLevel : 3,
                                         header      : false,
                                         iconItem        : icon€)
                    .modelChangesSwipeActions(duplicateItem : { duplicateItem(item) },
                                              deleteItem    : { deleteItem(item) })
                }.isDetailLink(true)
            }
            .onDelete(perform: removeItems)
            .onMove(perform: move)
        } label: {
            LabeledValueRowView(label       : label,
                                 value       : total,
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
        simulationReseter.notifyComputationInputsModification()
        uiState.resetSimulationView()
    }

    func addItem() {
        // ajouter un nouvel item à la liste
        let newItem = PeriodicInvestement(name: "Nouvel élément",
                                          delegateForAgeOf: family.ageOf)
        patrimoine.assets.periodicInvests.add(newItem)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func duplicateItem(_ item: PeriodicInvestement) {
        var newItem = item
        // générer un nouvel identifiant pour la copie
        newItem.id = UUID()
        newItem.name += "-copie"
        // duppliquer l'item de la liste
        patrimoine.assets.periodicInvests.add(newItem)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func deleteItem(_ item: PeriodicInvestement) {
        // supprimer l'item de la liste
        patrimoine.assets.periodicInvests.delete(item)
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
    }}
