//
//  PieChartTemplateView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 31/12/2021.
//

import SwiftUI
import AppFoundation
import Charts

struct PieChartTemplateView: NSUIViewRepresentable {

    // MARK: - Properties
    
    private var title  : String
    private var data   : [(label   : String, value   : Double)]
    private var uiView : PieChartView?

    // MARK: - Initializer
    
    internal init(title : String,
                  data  : [(label: String, value: Double)]) {
        self.title = title
        self.data  = data
    }
    
    // MARK: - Methods
    
    func makeDataSet() -> PieChartDataSet {
        let totalValue = data.reduce(0.0) {
            $0 + $1.value
        }
        let dataEntries: [PieChartDataEntry] = data.map { entry in
            let percent = (entry.value / totalValue).percentStringRounded
            return PieChartDataEntry(value: entry.value,
                                     label: entry.label + " (\(percent))")
        }
        
        let dataSet = PieChartDataSet(entries : dataEntries,
                                      label   : "Légende")
        dataSet.colors = [NSUIColor](ChartThemes.pieChartColorsTable[0 ... dataEntries.endIndex-1])
        dataSet.entryLabelFont                   = ChartThemes.ChartDefaults.xLargeLabelFont
        dataSet.entryLabelColor                  = ChartThemes.DarkChartColors.valueColor
        dataSet.drawIconsEnabled                 = false
        dataSet.automaticallyDisableSliceSpacing = true
        dataSet.sliceSpace                       = 2
        
        return dataSet
    }
    
    func updateData(of chartView: PieChartView) {
        // construire le DataSet
        let dataSet = makeDataSet()
        
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
        let chartView = PieChartView(title         : title,
                                     legendEnabled : false,
                                     smallLegend   : false)
        
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
    }}

struct PieChartTemplateView_Previews: PreviewProvider {
    static var previews: some View {
        PieChartTemplateView(title: "Titre\ndu\ngraphique",
                             data: [(label: "Label 1", value:  5000.0),
                                    (label: "Label 2", value: 10000.0),
                                    (label: "Label 3", value: 15000.0)])
    }
}
