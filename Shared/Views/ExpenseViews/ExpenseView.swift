//
//  ExpenseView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Persistence
import LifeExpense
import PatrimoineModel

struct ExpenseView: View {
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
            .defaultSideBarListStyle()
            //.listStyle(GroupedListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Dépenses")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    #if os(iOS) || os(tvOS)
                    EditButton()
                    #endif
                }
            }
            
            /// vue par défaut
            ExpenseSummaryView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ExpenseTotalView: View {
    @EnvironmentObject private var expenses: LifeExpensesDic

    var body: some View {
        Section {
            HStack {
                Text("Total")
                    .font(Font.system(size: 21,
                                      design: Font.Design.default))
                    .fontWeight(.bold)
                Spacer()
                Text(expenses.value(atEndOf: Date.now.year).€String)
                    .font(Font.system(size: 21,
                                      design: Font.Design.default))
            }
            .listRowBackground(ListTheme.rowsBaseColor)
        }
    }
}

struct ExpenseHeaderView: View {
    @EnvironmentObject var family: Family
    
    var body: some View {
        Section {
            NavigationLink(destination: ExpenseSummaryView()) {
                Text("Résumé").fontWeight(.bold)
            }
            .isiOSDetailLink(true)
        }
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

    var body: some View {
        Section {
            LabeledValueRowView(colapse     : $uiState.expenseViewState.colapseCategories[category.rawValue],
                                label       : category.displayString,
                                value       : expenses.perCategory[category]?.value(atEndOf: Date.now.year) ?? 0,
                                indentLevel : 0,
                                header      : true)
            if !uiState.expenseViewState.colapseCategories[category.rawValue] {
                // ajouter un nouvel item à liste des items
                NavigationLink(destination: ExpenseDetailedView(category          : category,
                                                                item              : nil,
                                                                expenses          : expenses,
                                                                simulationReseter : simulationReseter)) {
                    Label(title: { Text("Ajouter un élément...") },
                          icon : { Image(systemName: "plus.circle.fill").imageScale(.large) })
                        .foregroundColor(.accentColor)
                }
                
                // liste des items existants
                ForEach(expensesInCategory.items) { expense in
                    NavigationLink(destination: ExpenseDetailedView(category          : category,
                                                                    item              : expense,
                                                                    expenses          : expenses,
                                                                    simulationReseter : simulationReseter)) {
                        LabeledValueRowView(colapse     : .constant(true),
                                            label       : expense.name,
                                            value       : expense.value(atEndOf: Date.now.year),
                                            indentLevel : 3,
                                            header      : false)
                    }
                    .isiOSDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
    
    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulationReseter.reset()
        uiState.reset()
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
        func reset() {
            print("simluation.reset")
        }
    }
    static var simulationReseter = FakeSimulationReseter()
    static let dataStore  = Store()
    static var family     = try! Family(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var expenses   = try! LifeExpensesDic(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var patrimoine = try! Patrimoin(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var uiState    = UIState()

    static var previews: some View {
        NavigationView {
            ExpenseView(simulationReseter: simulationReseter)
                .environmentObject(dataStore)
                .environmentObject(family)
                .environmentObject(expenses)
                .environmentObject(patrimoine)
                .environmentObject(uiState)
        }
    }
}
