//
//  ExpenseListInCategorySidebar.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 03/04/2022.
//

import SwiftUI
import AppFoundation
import LifeExpense
import SimulationAndVisitors
import HelpersView

struct ExpenseListInCategorySidebar: View {
    @EnvironmentObject private var expenses : LifeExpensesDic
    @EnvironmentObject private var uiState  : UIState
    let simulationReseter : CanResetSimulationP
    let category          : LifeExpenseCategory
    private let indentLevel = 0
    private let iconAdd     = Image(systemName : "plus.circle.fill")
    private let iconCart    = Image(systemName : "cart")
    @State private var alertItem : AlertItem?

    private var expensesInCategory: Binding<LifeExpenseArray> {
        Binding(
            get: {
                expenses.perCategory[category] ?? LifeExpenseArray.empty
            },
            set: {
                expenses.perCategory[category] = $0
            }
        )
    }

    var body: some View {
        DisclosureGroup(isExpanded: $uiState.expenseViewState.expandCategories[category.rawValue]) {
            // ajout d'un nouvel item à la liste
            Button(
                action: addItem,
                label: {
                    Label(title: { Text("Ajouter un élément...") },
                          icon : { iconAdd.imageScale(.large) })
                })

            // liste des items existants
            ForEach(expensesInCategory.items) { $expense in
                NavigationLink(destination: ExpenseDetailedView(updateDependenciesToModel: updateDependenciesToModel,
                                                                category : category,
                                                                item     : $expense.transaction())) {
                    LabeledValueRowView(label       : expense.name,
                                        value       : expense.value(atEndOf: CalendarCst.thisYear),
                                        indentLevel : indentLevel + 2,
                                        header      : false,
                                        iconItem    : iconCart,
                                        kEuro       : false)
                    .modelChangesSwipeActions(duplicateItem : { duplicateItem(expense) },
                                              deleteItem    : { deleteItem(expense) })
                }.isDetailLink(true)
            }
            .onDelete(perform: removeItems)
            .onMove(perform: move)
        } label: {
            LabeledValueRowView(label       : category.displayString,
                                value       : expenses.perCategory[category]?.value(atEndOf: CalendarCst.thisYear) ?? 0,
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

    /// Remettre à zéro la simulation et sa vue
    private func resetSimulation() {
        simulationReseter.notifyComputationInputsModification()
        uiState.resetSimulationView()
    }

    private func updateDependenciesToModel() {
        // indiquer que les dépenses ont été modifiées
        expenses.perCategory[self.category]?.persistenceSM.process(event: .onModify)
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    private func addItem() {
        // ajouter un nouvel item à la liste
        let newItem = LifeExpense(name: "Nouvel élément")
        withAnimation {
            expenses.perCategory[self.category]?.add(newItem)
        }
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    private func duplicateItem(_ item: LifeExpense) {
        var newItem = item
        // générer un nouvel identifiant pour la copie
        newItem.id = UUID()
        newItem.name += "-copie"
        // duppliquer l'item de la liste
        withAnimation {
            expenses.perCategory[self.category]?.add(newItem)
        }
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    private func deleteItem(_ item: LifeExpense) {
        alertItem = AlertItem(
            title         : Text("Attention").foregroundColor(.red),
            message       : Text("La suppression est irréversible"),
            primaryButton : .destructive(Text("Supprimer"),
                                         action: {
                                             /// insert alert 1 action here
                                             // supprimer l'item de la liste
                                             withAnimation {
                                                 expenses.perCategory[self.category]?.delete(item)
                                             }
                                             // remettre à zéro la simulation et sa vue
                                             resetSimulation()
                                         }),
            secondaryButton: .cancel())
    }

    private func removeItems(at offsets: IndexSet) {
        alertItem = AlertItem(
            title         : Text("Attention").foregroundColor(.red),
            message       : Text("La suppression est irréversible"),
            primaryButton : .destructive(Text("Supprimer"),
                                         action: {
                                             /// insert alert 1 action here
                                             // supprimer la dépense
                                             expenses.perCategory[self.category]?.delete(at: offsets)
                                             // remettre à zéro la simulation et sa vue
                                             resetSimulation()
                                         }),
            secondaryButton: .cancel())
    }

    private func move(from source : IndexSet, to destination : Int) {
        expenses.perCategory[self.category]?.move(from : source,
                                                  to   : destination)
    }
}
