//
//  BubbleChartTemplateView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/01/2022.
//

import SwiftUI
import AppFoundation
import AndroidCharts
import ChartsExtensions
import HelpersView

struct BubbleChartTemplateView: NSUIViewRepresentable {

    // MARK: - Properties
    
    private var title                   : String?
    private var titleEnabled            : Bool
    private var legendEnabled           : Bool
    private var legendPosition          : LengendPosition
    private var smallLegend             : Bool
    private var averagesLinesEnabled    : Bool
    private var leftAxisFormatterChoice : AxisFormatterChoice
    private var xAxisFormatterChoice    : AxisFormatterChoice
    private var markers                 : [[String]]?
    private var data                    : [(x: Double, y: Double, size: Double)]
    private var uiView                  : BubbleChartView?
    
    // MARK: - Initializer
    
    init(title                   : String? = nil,
         titleEnabled            : Bool = false,
         legendEnabled           : Bool                = true,
         legendPosition          : LengendPosition     = .bottom,
         smallLegend             : Bool                = true,
         averagesLinesEnabled    : Bool                = false,
         leftAxisFormatterChoice : AxisFormatterChoice = .none,
         xAxisFormatterChoice    : AxisFormatterChoice = .none,
         markers                 : [[String]]?         = nil,
         data                    : [(x: Double, y: Double, size: Double)]) {
        self.title                   = title
        self.titleEnabled            = titleEnabled
        self.legendEnabled           = legendEnabled
        self.legendPosition          = legendPosition
        self.smallLegend             = smallLegend
        self.averagesLinesEnabled    = averagesLinesEnabled
        self.leftAxisFormatterChoice = leftAxisFormatterChoice
        self.xAxisFormatterChoice    = xAxisFormatterChoice
        self.markers                 = markers
        self.data                    = data
    }
    
    var total: Double {
        data.reduce(.zero) { result, element in
            result + element.size
        }
    }
    
    var xAverage: Double {
        let subTotal = data.reduce(.zero) { result, element in
            result + element.x * element.size
        }
        return subTotal / total
    }
    
    var yAverage: Double {
        let subTotal = data.reduce(.zero) { result, element in
            result + element.y * element.size
        }
        return subTotal / total
    }
    
    func makeDataSets(of chartView: BubbleChartView) -> [BubbleChartDataSet] {
        var dataSets = [BubbleChartDataSet]()
        
        let dataEntries: [BubbleChartDataEntry] = data.map { entry in
            BubbleChartDataEntry(x: entry.x, y: entry.y, size: entry.size)
        }
        let dataSet = BubbleChartDataSet(entries : dataEntries,
                                         label   : "Label")
        dataSet.drawIconsEnabled = false
        dataSet.setColor(ChartColorTemplates.colorful()[0], alpha: 0.5)
        dataSets.append(dataSet)
        
        if averagesLinesEnabled {
            let llX = ChartLimitLine(limit: xAverage, label: "label")
            llX.lineWidth        = 2
            llX.lineDashLengths  = [10, 10]
            llX.drawLabelEnabled = false
            llX.labelPosition    = .bottomRight
            llX.valueFont        = .systemFont(ofSize : 10)
            llX.valueTextColor   = ChartThemes.DarkChartColors.labelTextColor
            chartView.xAxis.removeAllLimitLines()
            chartView.xAxis.addLimitLine(llX)
            
            let llY = ChartLimitLine(limit: yAverage, label: "label")
            llY.lineWidth        = 2
            llY.lineDashLengths  = [10, 10]
            llY.drawLabelEnabled = false
            llY.labelPosition    = .bottomRight
            llY.valueFont        = .systemFont(ofSize : 10)
            llY.valueTextColor   = ChartThemes.DarkChartColors.labelTextColor
            chartView.leftAxis.removeAllLimitLines()
            chartView.leftAxis.addLimitLine(llY)
        }
        
        return dataSets
    }
    
    func updateData(of chartView: BubbleChartView) {
        // construire les DataSet
        let dataSets = makeDataSets(of: chartView)
        
        // ajouter les DataSet au Chartdata
        let data = BubbleChartData(dataSets: dataSets)
        data.setDrawValues(true)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(ChartThemes.ChartDefaults.valueFont)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKilo€Formatter))
        data.setHighlightCircleWidth(1.5)
        
        // ajouter le Chartdata au ChartView
        chartView.data = data
        let marker = chartView.marker as! StringMarker
        marker.markers = markers

        // actualiser le titre
        let title = titleEnabled ? (self.title == nil ? "TOTAL=\(total.k€String)" : self.title!) : ""
        chartView.chartDescription?.text = title
    }
    
    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> BubbleChartView {
        let title = titleEnabled ? (self.title == nil ? "TOTAL=\(total.k€String)" : self.title!) : ""
        
        // créer et configurer un nouveau graphique
        let chartView = BubbleChartView(title                   : title,
                                        legendEnabled           : legendEnabled,
                                        legendPosition          : legendPosition,
                                        smallLegend             : smallLegend,
                                        markers                 : markers,
                                        leftAxisFormatterChoice : leftAxisFormatterChoice,
                                        xAxisFormatterChoice    : xAxisFormatterChoice)
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: BubbleChartView, context: Context) {
        updateData(of: uiView)
        
        // animer la transition
        uiView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

struct BubbleChartTemplateView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return BubbleChartTemplateView(title                   : nil,
                                       titleEnabled            : true,
                                       legendEnabled           : true,
                                       legendPosition          : .left,
                                       smallLegend             : false,
                                       leftAxisFormatterChoice : .name(names: ["Value 1", "Value 2"]),
                                       xAxisFormatterChoice    : .name(names: ["X 1", "X 2"]),
                                       markers                 : [["M1", "M2"],
                                                                  ["M3", "M4"]],
                                       data                    : [(x: 0.0, y: 1.0, size: 15000.0),
                                                                  (x: 1.0, y: 0.0, size: 10000.0)])
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.uiState)
    }
}
