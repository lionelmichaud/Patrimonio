//
//  RealEstateSidebarView.swift
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

struct RealEstateSidebarView: View {
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var patrimoine : Patrimoin
    private let indentLevel = 2
    private let label       = "Immeuble"
    private let iconAdd     = Image(systemName : "plus.circle.fill")
    private let icon€       = Image(systemName   : "building.2.crop.circle")

    private var totalRealEstates: Double {
        patrimoine.assets.realEstates.value(atEndOf: CalendarCst.thisYear)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandEstate) {
            // ajout d'un nouvel item à la liste
            Button(
                action: addItem,
                label: {
                    Label(title: { Text("Ajouter un élément...") },
                          icon : { iconAdd.imageScale(.large) })
                })

                // liste des items
                ForEach($patrimoine.assets.realEstates.items) { $item in
                    NavigationLink(destination: RealEstateDetailedView(updateDependenciesToModel: resetSimulation,
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
                                 value       : totalRealEstates,
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
        let newItem = RealEstateAsset(name: "Nouvel élément",
                                      delegateForAgeOf: family.ageOf)
        patrimoine.assets.realEstates.add(newItem)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func duplicateItem(_ item: RealEstateAsset) {
        var newItem = item
        // générer un nouvel identifiant pour la copie
        newItem.id = UUID()
        newItem.name += "-copie"
        // duppliquer l'item de la liste
        patrimoine.assets.realEstates.add(newItem)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func deleteItem(_ item: RealEstateAsset) {
        // supprimer l'item de la liste
        patrimoine.assets.realEstates.delete(item)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func removeItems(at offsets: IndexSet) {
        patrimoine.assets.realEstates.delete(at: offsets)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.realEstates.move(from: source, to: destination)
    }
}
