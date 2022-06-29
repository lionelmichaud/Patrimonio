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
import HelpersView

struct DebtSidebarView: View {
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    let simulationReseter: CanResetSimulationP
    private let indentLevel = 2
    private let label       = "Dette"
    private let iconAdd     = Image(systemName : "plus.circle.fill")
    private let icon€       = Image(systemName   : "eurosign.circle.fill")
    @State private var alertItem : AlertItem?

    var totalDebt: Double {
        patrimoine.liabilities.debts.value(atEndOf: CalendarCst.thisYear)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $uiState.patrimoineViewState.liabViewState.expandDettes) {
            // ajout d'un nouvel item à la liste
            Button(
                action: addItem,
                label: {
                    Label(title: { Text("Ajouter un élément...") },
                          icon : { iconAdd.imageScale(.large) })
                })

            // liste des items
            ForEach($patrimoine.liabilities.debts.items) { $item in
                NavigationLink(destination: DebtDetailedView(updateDependenciesToModel: updateDependenciesToModel,
                                                             item: $item.transaction())) {
                    LabeledValueRowView(label       : item.name,
                                         value       : item.value(atEndOf: CalendarCst.thisYear),
                                         indentLevel : 3,
                                         header      : false,
                                         iconItem    : icon€)

                }.isDetailLink(true)
                    .modelChangesSwipeActions(duplicateItem : { duplicateItem(item) },
                                              deleteItem    : { deleteItem(item) })
            }
        } label: {
            LabeledValueRowView(label       : label,
                                 value       : totalDebt,
                                 indentLevel : indentLevel,
                                 header      : true,
                                 iconItem    : nil)
        }
        .alert(item: $alertItem, content: newAlert)
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

    private func updateDependenciesToModel() {
        // indiquer que les dépenses ont été modifiées
        patrimoine.liabilities.debts.persistenceSM.process(event: .onModify)
        resetSimulation()
    }

    func addItem() {
        // ajouter un nouvel item à la liste
        let newItem = Debt(name: "Nouvel élément",
                           delegateForAgeOf: family.ageOf)
        withAnimation {
            patrimoine.liabilities.debts.add(newItem)
        }
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func duplicateItem(_ item: Debt) {
        var newItem = item
        // générer un nouvel identifiant pour la copie
        newItem.id = UUID()
        newItem.name += "-copie"
        // duppliquer l'item de la liste
        withAnimation {
            patrimoine.liabilities.debts.add(newItem)
        }
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    func deleteItem(_ item: Debt) {
        alertItem = AlertItem(
            title         : Text("Attention").foregroundColor(.red),
            message       : Text("La suppression est irréversible"),
            primaryButton : .destructive(Text("Supprimer"),
                                         action: {
                                             /// insert alert 1 action here
                                             // supprimer l'item de la liste
                                             withAnimation {
                                                 patrimoine.liabilities.debts.delete(item)
                                             }
                                             // remettre à zéro la simulation et sa vue
                                             resetSimulation()
                                         }),
            secondaryButton: .cancel())
    }

    func removeItems(at offsets: IndexSet) {
        alertItem = AlertItem(
            title         : Text("Attention").foregroundColor(.red),
            message       : Text("La suppression est irréversible"),
            primaryButton : .destructive(Text("Supprimer"),
                                         action: {
                                             /// insert alert 1 action here
                                             patrimoine.liabilities.debts.delete(at: offsets)
                                             // remettre à zéro la simulation et sa vue
                                             resetSimulation()
                                         }),
            secondaryButton: .cancel())
    }

    func move(from source: IndexSet, to destination: Int) {
        patrimoine.liabilities.debts.move(from: source, to: destination)
    }
}
