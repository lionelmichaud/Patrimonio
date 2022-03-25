//
//  BarChartTemplateView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/01/2022.
//

import SwiftUI
import AppFoundation
import Charts
import ChartsExtensions
import HelpersView

struct BarChartTemplateView: NSUIViewRepresentable {
  
    // MARK: - Properties
    
    private var title  : String = "image"
    private var data   : [(x: Double, value: Double)]
    private var uiView : LineChartView?
    
    // MARK: - Initializer
    
    internal init(title : String,
                  data  : [(x: Double, value: Double)]) {
        self.title = title
        self.data  = data
    }
    
    // MARK: - Methods
    
    func makeDatasets(of chartView: LineChartView) -> [LineChartDataSet] {
        var dataSets = [LineChartDataSet]()
        var yVals1 = [ChartDataEntry]()
        
        yVals1 = data.map { element in
            ChartDataEntry(x: element.x,
                           y: element.value)
        }
        let set1 = LineChartDataSet(entries: yVals1,
                                    label: "Valeur",
                                    color: #colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1))
        
        dataSets.append(set1)
        return dataSets
    }
    
    func updateData(of chartView: LineChartView) {
        // créer les DataSet: LineChartDataSets
        let dataSets = makeDatasets(of: chartView)
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: 12.0)!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
    }
    
    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Répartition par Risque",
                                      smallLegend         : false,
                                      axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: LineChartView, context: Context) {
        updateData(of: uiView)
        
        // animer la transition
        uiView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}
