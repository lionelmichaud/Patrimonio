//
//  PieChartTemplateView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 31/12/2021.
//

import SwiftUI
import AppFoundation
import Charts
import ChartsExtensions
import HelpersView

/// Wrapper de LineChartView
struct PieChartTemplateView: NSUIViewRepresentable {

    // MARK: - Properties
    
    private var chartDescription   : String?
    private var centerText         : String?
    private var descriptionEnabled : Bool
    private var legendEnabled      : Bool
    private var legendPosition     : LengendPosition
    private var smallLegend        : Bool
    private var pieColors          : [NSUIColor]
    private var data               : [(label: String, value: Double)]
    private var uiView             : PieChartView?

    // MARK: - Initializer
    
    internal init(chartDescription   : String?,
                  centerText         : String?,
                  descriptionEnabled : Bool = true,
                  legendEnabled      : Bool = true,
                  legendPosition     : LengendPosition = .bottom,
                  smallLegend        : Bool = true,
                  pieColors          : [NSUIColor] = ChartThemes.pieChartColorsTable,
                  data               : [(label: String, value: Double)]) {
        self.chartDescription   = chartDescription
        self.centerText         = centerText
        self.descriptionEnabled = descriptionEnabled
        self.legendEnabled      = legendEnabled
        self.legendPosition     = legendPosition
        self.smallLegend        = smallLegend
        self.pieColors          = pieColors
        self.data               = data
    }
    
    // MARK: - Methods
    
    func makeDataSet(of chartView: PieChartView) -> PieChartDataSet {
        let totalValue = data.reduce(0.0) {
            $0 + $1.value
        }
        let dataEntries: [PieChartDataEntry] = data.map { entry in
            let percent = (entry.value / totalValue).percentStringRounded
            return PieChartDataEntry(value: entry.value,
                                     label: entry.label + " (\(percent))")
        }
        
        chartView.chartDescription?.text = chartDescription ?? "TOTAL=\(totalValue.k€String)"
        
        let dataSet = PieChartDataSet(entries : dataEntries,
                                      label   : "")
        dataSet.colors                           = pieColors
        dataSet.entryLabelFont                   = ChartThemes.ChartDefaults.xLargeLabelFont
        dataSet.entryLabelColor                  = ChartThemes.DarkChartColors.valueColor
        dataSet.drawIconsEnabled                 = false
        dataSet.automaticallyDisableSliceSpacing = true
        dataSet.sliceSpace                       = 2
        
        return dataSet
    }
    
    func updateData(of chartView: PieChartView) {
        // construire le DataSet
        let dataSet = makeDataSet(of: chartView)
        
        // ajouter les DataSet au Chartdata
        let data = PieChartData(dataSet: dataSet)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKilo€Formatter))
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
    }
    
    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> PieChartView {
        // créer et configurer un nouveau graphique
        let chartView = PieChartView(chartDescription   : chartDescription,
                                     centerText         : centerText,
                                     descriptionEnabled : descriptionEnabled,
                                     legendEnabled      : legendEnabled,
                                     legendPosition     : legendPosition,
                                     smallLegend        : smallLegend)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: PieChartView, context: Context) {
        updateData(of: uiView)
        
        // animer la transition
        uiView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

struct PieChartTemplateView_Previews: PreviewProvider {
    static var previews: some View {
        PieChartTemplateView(chartDescription   : "Description",
                             centerText         : "Titre\nCentre\nGraphique",
                             descriptionEnabled : true,
                             legendEnabled      : true,
                             legendPosition     : .left,
                             smallLegend        : false,
                             data: [(label: "Label 1", value:  5000.0),
                                    (label: "Label 2", value: 10000.0),
                                    (label: "Label 3", value: 15000.0)])
    }
}
