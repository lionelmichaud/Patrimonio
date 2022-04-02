//
//  ExpenseView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct ExpenseSidebarView: View {
    @EnvironmentObject private var dataStore : Store
    @EnvironmentObject private var expenses  : LifeExpensesDic
    let simulationReseter: CanResetSimulationP

    private var categories: [(LifeExpenseCategory, LifeExpenseArray)] {
        expenses.perCategory.sorted(by: \.key.displayString)
    }
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // résumé
                ExpenseHeaderView()
                
                if dataStore.activeDossier != nil {
                    ExpenseTotalView()
                    
                    // pour chaque catégorie de dépense, afficher la liste des dépenses
                    ForEach(categories, id: \.0) { (category, expenses) in
                        ExpenseListInCategory(simulationReseter : simulationReseter,
                                              category          : category,
                                              expensesInCategory: expenses)
                    }
                }
            }
            .listStyle(.sidebar)
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Dépenses")
            .toolbar {
                EditButton()
            }

            /// vue par défaut
            ExpenseSummaryView()
        }
        .navigationViewStyle(.columns)
    }
}

struct ExpenseTotalView: View {
    @EnvironmentObject private var expenses: LifeExpensesDic

    var body: some View {
        LabeledValueRowView2(label       : "Total",
                             value       : expenses.value(atEndOf: CalendarCst.thisYear),
                             indentLevel : 0,
                             header      : true,
                             iconItem    : nil)
    }
}

struct ExpenseHeaderView: View {
    var body: some View {
        NavigationLink(destination: ExpenseSummaryView()) {
            Label(title: { Text("Synthèse") },
                  icon : { Image(systemName: "cart.fill").imageScale(.large) })
            .font(.title3)
        }.isDetailLink(true)
    }
}

struct ExpenseListInCategory: View {
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var uiState    : UIState
    let simulationReseter : CanResetSimulationP
    let category          : LifeExpenseCategory
    var expensesInCategory: LifeExpenseArray
    private let indentLevel = 0
    private let iconAdd     = Image(systemName : "plus.circle.fill")
    private let iconCart    = Image(systemName : "cart")

    var body: some View {
        DisclosureGroup(isExpanded: $uiState.expenseViewState.expandCategories[category.rawValue]) {
            // ajouter un nouvel item à liste des items
            NavigationLink(destination: ExpenseDetailedView(category          : category,
                                                            item              : nil,
                                                            expenses          : expenses,
                                                            simulationReseter : simulationReseter)) {
                Label(title: { Text("Ajouter un élément...") },
                      icon : { iconAdd.imageScale(.large) })
                .foregroundColor(.accentColor)
            }

            // liste des items existants
            ForEach(expensesInCategory.items) { expense in
                NavigationLink(destination: ExpenseDetailedView(category          : category,
                                                                item              : expense,
                                                                expenses          : expenses,
                                                                simulationReseter : simulationReseter)) {
                    LabeledValueRowView2(label       : expense.name,
                                         value       : expense.value(atEndOf: CalendarCst.thisYear),
                                         indentLevel : indentLevel + 2,
                                         header      : false,
                                         iconItem    : iconCart,
                                         kEuro       : false)
                }.isDetailLink(true)
            }
            .onDelete(perform: removeItems)
            .onMove(perform: move)
        } label: {
            LabeledValueRowView2(label       : category.displayString,
                                 value       : expenses.perCategory[category]?.value(atEndOf: CalendarCst.thisYear) ?? 0,
                                 indentLevel : indentLevel,
                                 header      : true,
                                 iconItem    : nil)
        }
    }
    
    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulationReseter.notifyComputationInputsModification()
        uiState.resetSimulationView()
        // supprimer la dépense
        expenses.perCategory[self.category]?.delete(at: offsets)
    }
    
    func move(from source    : IndexSet, to destination : Int) {
        expenses.perCategory[self.category]?.move(from : source,
                                                  to   : destination)
    }
}

struct ExpenseView_Previews: PreviewProvider {
    struct FakeSimulationReseter: CanResetSimulationP {
        func notifyComputationInputsModification() {
            print("simluation.reset")
        }
    }
    static var simulationReseter = FakeSimulationReseter()
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return TabView {
            ExpenseSidebarView(simulationReseter: simulationReseter)
                .tabItem { Label("Dépenses", systemImage: "cart.fill") }
                .tag(UIState.Tab.expense)
                .environmentObject(TestEnvir.dataStore)
                .environmentObject(TestEnvir.family)
                .environmentObject(TestEnvir.expenses)
                .environmentObject(TestEnvir.patrimoine)
                .environmentObject(TestEnvir.uiState)
        }
    }
}
