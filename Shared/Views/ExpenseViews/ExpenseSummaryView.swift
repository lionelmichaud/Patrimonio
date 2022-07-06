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

enum ExpenseChartTypeEnum {
    case valueChart
    case timelineChart

    var pickerImage: Image {
        switch self {
            case .valueChart : return Image(systemName: "chart.bar.doc.horizontal")
            case .timelineChart : return Image(systemName: "chart.line.flattrend.xyaxis")
        }
    }
}

struct ExpenseSummaryView: View {
    @EnvironmentObject private var dataStore : Store
    @EnvironmentObject private var expenses  : LifeExpensesDic
    @EnvironmentObject private var uiState   : UIState
    let minDate = Date.now.year
    let maxDate = Date.now.year + 40

    @State
    private var chartType = ExpenseChartTypeEnum.valueChart

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

    // choix des paramètres du graphique
    private var chartParametersView: some View {
        VStack {
            HStack {
                // sélection du type de graphique à afficher
                Picker("Présentation", selection: $chartType.animation()) {
                    ExpenseChartTypeEnum.valueChart.pickerImage.tag(ExpenseChartTypeEnum.valueChart)
                    ExpenseChartTypeEnum.timelineChart.pickerImage.tag(ExpenseChartTypeEnum.timelineChart)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 100)

                // sélection des catégories à afficher: Toutes/Une
                if chartType == .valueChart {
                    Toggle("Toutes les catégories", isOn: $allCategories.animation())
                        .toggleStyle(.button)
                        .buttonStyle(.bordered)
                }

                // sélection de l'unique catégorie à afficher
                if chartType == .timelineChart || (chartType == .valueChart && !allCategories) {
                    HStack {
                        Text("Catégorie de dépense sélectionnée")
                        CasePicker(pickedCase: $uiState.expenseViewState.selectedCategory.animation(), label: "Catégories de dépenses")
                    }
                }
                Spacer()
            }

            // choix de l'année / évaluation annuelle des dépenses
            HStack {
                Text("Evaluation en ") + Text(String(Int(uiState.expenseViewState.evalDate)))
                Slider(value : $uiState.expenseViewState.evalDate.animation(),
                       in    : minDate.double() ... maxDate.double(),
                       step  : 1,
                       onEditingChanged: {_ in
                })
                Text(totalExpense)
                    .bold()
            }

            // paramétrage du graphique détaillé
            if chartType == .timelineChart && !allCategories {
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
    }

    // graphique
    private var chartView: some View {
        // graphique
        Group {
            switch chartType {
                case .valueChart:
                    if #available(iOS 16.0, *) {
                        ExpenseSummaryChartView(evalDate      : uiState.expenseViewState.evalDate,
                                                allCategories : allCategories,
                                                category      : uiState.expenseViewState.selectedCategory)
                        .frame(maxHeight: .infinity)
                    } else {
                        Text("Vue disponible à partir de iOS 16 seulement")
                    }

                case .timelineChart:
                    if #available(iOS 16.0, *) {
                        ExpenseDetailedChartUIView(endDate  : uiState.expenseViewState.endDate,
                                                 evalDate : uiState.expenseViewState.evalDate,
                                                 category : uiState.expenseViewState.selectedCategory)
                        .padding()
                        .frame(maxHeight: .infinity)
                    } else {
                        ExpenseDetailedChartUIView(endDate  : uiState.expenseViewState.endDate,
                                                 evalDate : uiState.expenseViewState.evalDate,
                                                 category : uiState.expenseViewState.selectedCategory)
                        .padding()
                        .frame(maxHeight: .infinity)
                    }

            }
        }
    }

    var body: some View {
        if dataStore.activeDossier != nil {
            GeometryReader { geometry in
                VStack {
                    // choix des paramètres du graphique
                    chartParametersView

                    // graphique
                    chartView
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
