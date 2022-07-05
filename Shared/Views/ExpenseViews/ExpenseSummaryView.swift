//
//  ExpenseSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Persistence
import LifeExpense
import HelpersView

struct ExpenseSummaryView: View {
    @EnvironmentObject private var dataStore : Store
    @EnvironmentObject private var expenses  : LifeExpensesDic
    @EnvironmentObject private var uiState   : UIState
    let minDate = CalendarCst.thisYear
    let maxDate = CalendarCst.thisYear + 40

    @State
    private var allCategories = true

    @State
    private var alertItem: AlertItem?

    @State
    private var showInfoPopover = false

    private let popOverTitle   = "Contenu du graphique:"
    private let popOverMessage =
        """
        Projection dans le temps des dépenses par catégories.
        """
    private var totalExpense: String {
        if allCategories {
            return expenses.value(atEndOf: Int(uiState.expenseViewState.evalDate)).€String

        } else if let selectedExpenses = expenses.perCategory[uiState.expenseViewState.selectedCategory] {
            return selectedExpenses.value(atEndOf: Int(uiState.expenseViewState.evalDate)).€String

        } else {
            return "?"
        }
    }

    var body: some View {
        if dataStore.activeDossier != nil {
            GeometryReader { geometry in
                VStack {
                    VStack {
                        // sélection des catégories à afficher
                        HStack {
                            Toggle("Toutes les catégories", isOn: $allCategories)
                                .toggleStyle(.button)
                                .buttonStyle(.bordered)
                            Spacer()

                            if !allCategories {
                                HStack {
                                    Text("Catégories de dépenses")
                                    CasePicker(pickedCase: $uiState.expenseViewState.selectedCategory, label: "Catégories de dépenses")
                                    //.pickerStyle(.menu)
                                }
                            }
                            Spacer()
                        }

                        // évaluation annuelle des dépenses
                        HStack {
                            Text("Evaluation en ") + Text(String(Int(uiState.expenseViewState.evalDate)))
                            Slider(value : $uiState.expenseViewState.evalDate,
                                   in    : minDate.double() ... maxDate.double(),
                                   step  : 1,
                                   onEditingChanged: {_ in
                            })
                            Text(totalExpense)
                        }

                        // paramétrage du graphique détaillé
                        if !allCategories {
                            HStack {
                                Text("Période de ") + Text(String(minDate))
                                Slider(value : $uiState.expenseViewState.endDate,
                                       in    : minDate.double() ... maxDate.double(),
                                       step  : 5,
                                       onEditingChanged: {
                                    print("\($0)")
                                })
                                Text("à ") + Text(String(Int(uiState.expenseViewState.endDate)))
                            }
                        }
                    }
                    .padding(.horizontal)

                    // graphique
                    if allCategories {
                        if #available(iOS 16.0, *) {
                            ExpenseSummaryChartView(evalDate : uiState.expenseViewState.evalDate)
                                .frame(maxHeight: .infinity)
                        } else {
                            Text("Vue non disponible (iOS 16 seulement)")
                        }
                    } else {
                        ExpenseDetailedChartView(endDate  : uiState.expenseViewState.endDate,
                                                 evalDate : uiState.expenseViewState.evalDate,
                                                 category : uiState.expenseViewState.selectedCategory)
                        .padding()
                        .frame(maxHeight: .infinity)
                    }
                }
                .alert(item: $alertItem, content: newAlert)
                .navigationTitle("Synthèse")
                .navigationBarTitleDisplayModeInline()
                .toolbar {
                    // afficher info-bulle
                    ToolbarItemGroup(placement: .automatic) {
                        Button(action: { self.showInfoPopover = true },
                               label : {
                            Image(systemName: "info.circle")
                        })
                        .popover(isPresented: $showInfoPopover) {
                            PopOverContentView(title       : popOverTitle,
                                               description : popOverMessage)
                        }

                        /// bouton Exporter fichiers du dossier actif
                        Button(action: { share(geometry: geometry) },
                               label: {
                            Image(systemName: "square.and.arrow.up.on.square")
                                .imageScale(.large)
                        })
                        //.buttonStyle(.bordered)
                    }
                }
            }
        } else {
            NoLoadedDossierView()
        }
    }

    // MARK: - Methods

    private func share(geometry: GeometryProxy) {
        // collecte des URL des fichiers contenus dans le dossier
        let fileNameKeys = ["LifeExpense"]
        shareFiles(dataStore: dataStore,
                   fileNames: fileNameKeys,
                   alertItem: &alertItem,
                   geometry: geometry)
    }
}

struct ExpenseSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ExpenseSummaryView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.uiState)
    }
}
