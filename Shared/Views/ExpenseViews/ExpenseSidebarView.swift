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
import SimulationAndVisitors

struct ExpenseSidebarView: View {
    @EnvironmentObject private var dataStore : Store
    @EnvironmentObject private var expenses  : LifeExpensesDic
    let simulationReseter: CanResetSimulationP

    private var categories: [(LifeExpenseCategory, LifeExpenseArray)] {
        expenses.perCategory.sorted(by: \.key.displayString)
    }

    private var sortedCategories: [LifeExpenseCategory] {
        LifeExpenseCategory.allCases.sorted(by: \.displayString)
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
//                    ForEach(sortedCategories, id: \.displayString) { category in
//                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
//                                                     category          : category)
//                    }
                    Group {
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .abonnements)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .autres)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .cadeaux)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .educationFamille)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .logement)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .loisirs)
                    }
                    Group {
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .sante)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .services)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .vehicules)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .vieQuotidienne)
                        ExpenseListInCategorySidebar(simulationReseter : simulationReseter,
                                                     category          : .voyageTransport)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationViewStyle(.columns)
            .navigationTitle("Dépenses")
            .environment(\.horizontalSizeClass, .regular)
            .toolbar {
                EditButton()
            }

            /// vue par défaut
            ExpenseSummaryView()
        }
    }
}

struct ExpenseTotalView: View {
    @EnvironmentObject private var expenses: LifeExpensesDic

    var body: some View {
        LabeledValueRowView(label       : "Totale des dépenses",
                            value       : expenses.value(atEndOf: CalendarCst.thisYear),
                            indentLevel : 0,
                            header      : true,
                            iconItem    : nil)
        .padding([.top, .bottom])
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
                .environmentObject(TestEnvir.uiState)
        }
    }
}
