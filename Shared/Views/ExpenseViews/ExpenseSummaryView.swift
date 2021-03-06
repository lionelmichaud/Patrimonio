//
//  ExpenseSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git

struct ExpenseSummaryView: View {
    @EnvironmentObject var family  : Family
    @EnvironmentObject var uiState : UIState
    let minDate = Date.now.year
    let maxDate = Date.now.year + 40
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des dépenses par catégories.
        """

    var body: some View {
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
        //: ### General
        chartView.pinchZoomEnabled          = true
        chartView.doubleTapToZoomEnabled    = true
        chartView.dragEnabled               = true
        chartView.drawGridBackgroundEnabled = true
        chartView.gridBackgroundColor       = ChartThemes.DarkChartColors.gridBackgroundColor
        chartView.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        chartView.borderColor               = ChartThemes.DarkChartColors.borderColor
        chartView.borderLineWidth           = 1.0
        chartView.drawBordersEnabled        = false
        chartView.drawValueAboveBarEnabled  = false
        chartView.drawBarShadowEnabled      = false
        chartView.fitBars                   = true
        chartView.highlightFullBarEnabled   = false
        //chartView.maxVisibleCount = 60

        //: ### xAxis value formatter
        let xAxisValueFormatter = NamedValueFormatter()

        //: ### xAxis
        let xAxis = chartView.xAxis
        xAxis.drawAxisLineEnabled  = true
        xAxis.labelPosition        = .bottom
        xAxis.labelFont            = ChartThemes.ChartDefaults.largeLabelFont
        xAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        xAxis.granularityEnabled   = false
        xAxis.granularity          = 1
        xAxis.labelCount           = 200
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled  = true
        xAxis.valueFormatter       = xAxisValueFormatter
        //xAxis.wordWrapEnabled      = true
        //xAxis.wordWrapWidthPercent = 0.5
        //xAxis.axisMinimum         = 0

        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.enabled              = true
        leftAxis.drawAxisLineEnabled  = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.labelFont            = ChartThemes.ChartDefaults.largeLabelFont
        leftAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.granularityEnabled   = true // autoriser la réducion du nombre de label
        leftAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        leftAxis.labelCount           = 15   // nombre maxi
        leftAxis.axisMinimum          = Date.now.year.double()
        leftAxis.axisMaximum          = endDate

        //: ### RightAxis
        let rightAxis = chartView.rightAxis
        rightAxis.enabled              = true
        rightAxis.drawAxisLineEnabled  = true
        rightAxis.drawGridLinesEnabled = false
        rightAxis.labelFont            = ChartThemes.ChartDefaults.largeLabelFont
        rightAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        rightAxis.granularityEnabled   = true // autoriser la réducion du nombre de label
        rightAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        rightAxis.labelCount           = 15   // nombre maxi
        rightAxis.axisMinimum          = Date.now.year.double()
        rightAxis.axisMaximum          = endDate

        //: ### Legend
        let legend = chartView.legend
        legend.enabled             = false
        legend.font                = ChartThemes.ChartDefaults.smallLegendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.formSize            = 8
        legend.drawInside          = false
        legend.horizontalAlignment = .left
        legend.verticalAlignment   = .bottom
        legend.orientation         = .horizontal
        legend.xEntrySpace         = 4

        #if os(iOS) || os(tvOS)
        //: ## bulle d'info
        let marker = ExpenseMarkerView(color              : ChartThemes.BallonColors.color,
                                       font               : ChartThemes.ChartDefaults.baloonfont,
                                       textColor          : ChartThemes.BallonColors.textColor,
                                       insets             : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                       xAxisValueFormatter: chartView.xAxis.valueFormatter!,
                                       yAxisValueFormatter: chartView.leftAxis.valueFormatter!)
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        #endif

        chartView.fitBars = true

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
        let chartView = HorizontalBarChartView()
        format(chartView)
        return chartView
    }

    func updateUIView(_ uiView: HorizontalBarChartView, context: Context) {
        updateData(of: uiView)
    }

    #else
    func makeNSView(context: Context) -> HorizontalBarChartView {
        let chartView = HorizontalBarChartView()
        format(chartView)
        return chartView
    }

    func updateNSView(_ nsView: HorizontalBarChartView, context: Context) {
        updateData(of: nsView)
    }
    #endif
}

struct ExpenseSummaryView_Previews: PreviewProvider {
    static var family     = Family()
    static var uiState    = UIState()

    static var previews: some View {
        ExpenseSummaryView()
            .environmentObject(family)
            .environmentObject(uiState)
    }
}
