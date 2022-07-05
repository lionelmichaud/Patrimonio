//
//  ExpenseDetailedChartView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/07/2022.
//

import SwiftUI
import AppFoundation
import HelpersView
import LifeExpense
import Charts
import ChartsExtensions

// MARK: - Wrappers de UIView

struct ExpenseDetailedChartView: NSUIViewRepresentable {
    @EnvironmentObject var expenses : LifeExpensesDic
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
        let namedValuedTimeFrameTable = expenses.namedValuedTimeFrameTable(category: category)

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
        dataSet.colors           = ExpenseDetailedChartView.ColorsTable
        dataSet.drawIconsEnabled = false

        return dataSet
    }

    func format(_ chartView: HorizontalBarChartView) {
        //: ### LeftAxis
        let leftAxis = chartView.leftAxis
        leftAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        leftAxis.labelCount           = 15   // nombre maxi
        leftAxis.axisMinimum          = CalendarCst.thisYear.double()
        leftAxis.axisMaximum          = endDate

        //: ### RightAxis
        let rightAxis = chartView.rightAxis
        rightAxis.granularity          = 1    // à utiliser sans dépasser .labelCount
        rightAxis.labelCount           = 15   // nombre maxi
        rightAxis.axisMinimum          = CalendarCst.thisYear.double()
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

        // mettre à jour en fonction de la position du slider de plage de temps à afficher
        chartView.leftAxis.axisMaximum  = endDate
        chartView.rightAxis.axisMaximum = endDate

        // mettre à jour en fonction de la position du slider de date d'évaluation
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
