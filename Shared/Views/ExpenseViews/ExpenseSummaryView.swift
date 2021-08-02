//
//  ExpenseSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Persistence
import Charts // https://github.com/danielgindi/Charts.git

struct ExpenseSummaryView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var family  : Family
    @EnvironmentObject private var uiState : UIState
    let minDate = Date.now.year
    let maxDate = Date.now.year + 40
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des dépenses par catégories.
        """
    
    var body: some View {
        if dataStore.activeDossier != nil {
            VStack {
                // évaluation annuelle des dépenses
                HStack {
                    Text("Evaluation en ") + Text(String(Int(uiState.expenseViewState.evalDate)))
                    Slider(value : $uiState.expenseViewState.evalDate,
                           in    : minDate.double() ... maxDate.double(),
                           step  : 1,
                           onEditingChanged: {_ in
                           })
                    if let expenses = self.family.expenses.perCategory[uiState.expenseViewState.selectedCategory] {
                        Text(expenses.value(atEndOf: Int(self.uiState.expenseViewState.evalDate)).€String)
                    }
                }
                .padding(.horizontal)
                
                // choix de la catégorie des dépenses
                CasePicker(pickedCase: $uiState.expenseViewState.selectedCategory, label: "Catégories de dépenses")
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                
                // graphique
                ExpenseSummaryChartView(endDate  : uiState.expenseViewState.endDate,
                                        evalDate : uiState.expenseViewState.evalDate,
                                        category : uiState.expenseViewState.selectedCategory)
                    .padding()
                // paramétrage du graphique
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
                .padding(.horizontal)
                .padding(.bottom)
                .navigationTitle("Résumé")
                .navigationBarTitleDisplayModeInline()
                .toolbar {
                    // afficher info-bulle
                    ToolbarItem(placement: .automatic) {
                        Button(action: { self.showInfoPopover = true },
                               label : {
                                Image(systemName: "info.circle")
                               })
                            .popover(isPresented: $showInfoPopover) {
                                PopOverContentView(title       : popOverTitle,
                                                   description : popOverMessage)
                            }
                    }
                }
            }
        } else {
            NoLoadedDossierView()
        }
    }
}

// MARK: - Wrappers de UIView

struct ExpenseSummaryChartView: NSUIViewRepresentable {
    @EnvironmentObject var family : Family
    let endDate  : Double
    let evalDate : Double
    let category : LifeExpenseCategory
    
    static let ColorsTable: [NSUIColor] = [#colorLiteral(red: 0.9171036869, green: 0.9171036869, blue: 0.9171036869, alpha: 0), #colorLiteral(red: 0.843980968, green: 0.4811213613, blue: 0.2574525177, alpha: 1)]
    
    /// Créer le dataset du graphique
    /// - Returns: dataset
    func getExpenseDataSet(formatter : NamedValueFormatter,
                           marker    : IMarker?) -> BarChartDataSet {
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet
        
        // pour chaque categorie de dépense
        //for _ in LifeExpenseCategory.allCases {
        // pour chaque dépense
        //  chercher le nom de la dépense
        //  chercher la position de la dépense dans le tableau des dépense
        //  chercher les dates de début et de fin
        let namedValuedTimeFrameTable = family.expenses.namedValuedTimeFrameTable(category: category)
        
        // mettre à jour les noms des dépenses dans le formatteur de l'axe X
        formatter.names = namedValuedTimeFrameTable.map { (name, _, _, _, _) in
            name
        }
        
        #if os(iOS) || os(tvOS)
        if let baloonMarker = marker as? ExpenseMarkerView {
            // mettre à jour les valeurs des dépenses dans le formatteur de bulle d'info
            baloonMarker.amounts = namedValuedTimeFrameTable.map { (_, value, _, _, _) in
                value
            }
            baloonMarker.prop = namedValuedTimeFrameTable.map { (_, _, prop, _, _) in
                prop
            }
            baloonMarker.firstYearDuration = namedValuedTimeFrameTable.map { (_, _, _, _, firstYearDuration) in
                firstYearDuration
            }
        }
        #endif
        
        // générer les 2 séries pour chaque dépense
        dataEntries += namedValuedTimeFrameTable.map { (_, _, _, idx, firstYearDuration) in
            BarChartDataEntry(x       : idx.double(),
                              yValues : firstYearDuration.map { $0.double() })
        }
        
        //}
        dataSet = BarChartDataSet(entries : dataEntries)
        dataSet.colors           = ExpenseSummaryChartView.ColorsTable
        dataSet.drawIconsEnabled = false
        
        return dataSet
    }
    
    func format(_ chartView: HorizontalBarChartView) {
        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        leftAxis.labelCount           = 15   // nombre maxi
        leftAxis.axisMinimum          = Date.now.year.double()
        leftAxis.axisMaximum          = endDate
        
        //: ### RightAxis
        let rightAxis = chartView.rightAxis
        rightAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        rightAxis.labelCount           = 15   // nombre maxi
        rightAxis.axisMinimum          = Date.now.year.double()
        rightAxis.axisMaximum          = endDate
        
        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
    }
    
    func updateData(of chartView: HorizontalBarChartView) {
        chartView.clear()
        //: ### BarChartData
        let dataSet = getExpenseDataSet(formatter : chartView.xAxis.valueFormatter as! NamedValueFormatter,
                                        marker    : chartView.marker)
        
        // ajouter le dataset au graphique
        let data = BarChartData(dataSet: dataSet)
        
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)
        data.barWidth = 0.5
        
        // mettre à joure en fonction de la position du slider de plage de temps à afficher
        chartView.leftAxis.axisMaximum  = endDate
        chartView.rightAxis.axisMaximum = endDate
        
        // mettre à joure en fonction de la position du slider de date d'évaluation
        let ll1 = ChartLimitLine(limit: evalDate+0.5, label: "date d'évaluation")
        ll1.lineWidth       = 2
        ll1.lineDashLengths = [10, 10]
        ll1.labelPosition   = .bottomRight
        ll1.valueFont       = .systemFont(ofSize : 10)
        ll1.valueTextColor  = ChartThemes.DarkChartColors.labelTextColor
        chartView.leftAxis.removeAllLimitLines()
        chartView.leftAxis.addLimitLine(ll1)
        
        chartView.data = data
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
    }
    
    #if os(iOS) || os(tvOS)
    func makeUIView(context: Context) -> HorizontalBarChartView {
        let chartView = HorizontalBarChartView(title: "Dépenses", smallLegend: false)
        format(chartView)
        return chartView
    }
    
    func updateUIView(_ uiView: HorizontalBarChartView, context: Context) {
        updateData(of: uiView)
    }
    
    #else
    func makeNSView(context: Context) -> HorizontalBarChartView {
        let chartView = HorizontalBarChartView(title: "Dépenses", smallLegend: false)
        format(chartView)
        return chartView
    }
    
    func updateNSView(_ nsView: HorizontalBarChartView, context: Context) {
        updateData(of: nsView)
    }
    #endif
}

struct ExpenseSummaryView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static var family     = Family()
    static var uiState    = UIState()
    
    static var previews: some View {
        ExpenseSummaryView()
            .environmentObject(dataStore)
            .environmentObject(family)
            .environmentObject(uiState)
    }
}
