//
//  HistogramView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Statistics
import AndroidCharts // https://github.com/danielgindi/Charts.git
import ChartsExtensions

/// Présentation graphique d'un Historgramme
///
/// Le graphique contient:
///  - une courbe de la densité de probabilité PDF
///  - une courbe de la densité de probabilité cumulée CDF
///  - une ligne limite verticale: valeur objectif à atteindre (optionel)
///  - une ligne limite horizontale: probabilité minimale acceptable  (optionel)
///
/// Usage:
/// ```
///     HistogramView(histogram           : kpi.histogram,
///                   xLimitLine          : kpi.objective,
///                   yLimitLine          : kpi.probaObjective,
///                   xAxisFormatterChoice: .k€)
/// ```
///
struct HistogramView : UIViewRepresentable {
    static var uiView        : LineChartView?
    var histogram            : Histogram
    var xLimitLine           : Double?
    var yLimitLine           : Double?
    var xAxisFormatterChoice : AxisFormatterChoice

    func format(_ chartView: LineChartView) {
        let leftAxis = chartView.leftAxis
        leftAxis.axisMinimum                     = 0.0
        leftAxis.axisMaximum                     = 1.0
        //leftAxis.axisMaxLabels                   = 11
        leftAxis.granularityEnabled              = true
        leftAxis.setLabelCount(11, force : true)
        // leftAxis.granularity                  = 0.1
        // leftAxis.axisMaximum                  = 200
        leftAxis.valueFormatter                  = AxisFormatterChoice.percent.IaxisFormatter()
        leftAxis.drawLimitLinesBehindDataEnabled = true
        leftAxis.removeAllLimitLines()

        let rightAxis = chartView.rightAxis
        rightAxis.enabled                         = false
        rightAxis.axisMinimum                     = 0
        rightAxis.granularityEnabled              = true
        rightAxis.setLabelCount(11, force : true)
        rightAxis.valueFormatter                  = AxisFormatterChoice.percent.IaxisFormatter()
        rightAxis.drawLimitLinesBehindDataEnabled = true
        rightAxis.removeAllLimitLines()

        let xAxis = chartView.xAxis
        xAxis.axisMinimum                     = 0
        xAxis.granularityEnabled              = true
        xAxis.valueFormatter                  = xAxisFormatterChoice.IaxisFormatter()
        xAxis.labelRotationAngle              = 45
        xAxis.labelFont                       = NSUIFont(name : "HelveticaNeue-Light", size : 13.0)!
        xAxis.drawLimitLinesBehindDataEnabled = false
        xAxis.removeAllLimitLines()

        /// ligne de limite Y: proba minimum à atteindre (axe Y)
        if let yLimitLine = yLimitLine {
            // y-axis limit line
            let pObjectiveLine = ChartLimitLine(limit         : 1.0 - yLimitLine,
                                                label         : "Pobjectif: \(Int(yLimitLine * 100))% de valeurs > Valeur Objectif",
                                                labelPosition : .topLeft,
                                                lineColor     : .red)
            leftAxis.addLimitLine(pObjectiveLine)
            // x-axis limit line
            if let xLimitLine = histogram.percentile(for: 1.0 - yLimitLine) {
                let objectiveLine = ChartLimitLine(limit         : xLimitLine,
                                                   label         : "Valeur atteinte: " + xLimitLine.k€String,
                                                   labelPosition : .topRight,
                                                   lineColor     : .green)
                xAxis.addLimitLine(objectiveLine)
            }
        }

        /// ligne de limite X: valeure objectif (axe X)
        // x-axis limit line
        if let xLimitLine = xLimitLine {
            let objectiveLine = ChartLimitLine(limit         : xLimitLine,
                                               label         : "Valeur objectif: " + xLimitLine.k€String,
                                               labelPosition : .topRight,
                                               lineColor     : .red)
            xAxis.addLimitLine(objectiveLine)
        }

        /// ajouter un Marker
        let marker = XYMarkerView(color               : ChartThemes.BallonColors.color,
                                  font                : ChartThemes.ChartDefaults.baloonfont,
                                  textColor           : ChartThemes.BallonColors.textColor,
                                  insets              : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter : xAxis.valueFormatter!,
                                  yAxisValueFormatter : leftAxis.valueFormatter!)
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
    }

    func updateData(of chartView: LineChartView) {
        // créer les DataSet: LineChartDataSets
        let dataSets = LineChartHistogramVisitor(element: histogram).dataSets

        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: 12.0)!)

        // ajouter le Chartdata au ChartView
        chartView.data = data

        chartView.data?.notifyDataChanged()
    }

    func makeUIView(context: Context) -> LineChartView {
        /// créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : histogram.name,
                                      axisFormatterChoice : AxisFormatterChoice.percent)
        format(chartView)

        /// animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        /// mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        UniformChartView.uiView = chartView
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        uiView.clear()
        //uiView.data?.clearValues()
        
        updateData(of: uiView)

        uiView.notifyDataSetChanged()
    }
}

struct HistogramView_Previews: PreviewProvider {
    static func histogramTest() -> Histogram {
        /// générateur de nombre aléatoire suivant une distribution Beta
        var betaGenerator = BetaRandomGenerator(minX  : 0.0,
                                                maxX  : 5.0,
                                                alpha : 2.0,
                                                beta  : 8.0)
        betaGenerator.initialize()
        /// tirages aléatoires selon distribution en Beta et ajout à un histogramme
        let nbRandomSamples = 10000
        let sequence = betaGenerator.sequence(of: nbRandomSamples)
        var histogram = Histogram(distributionType : .continuous,
                                  openEnds         : false,
                                  Xmin             : 0.0,
                                  Xmax             : 5.0,
                                  bucketNb         : 50)
        histogram.record(sequence)
        return histogram
    }
    static var histogram = histogramTest()
    static var previews: some View {
        HistogramView(histogram : histogramTest(),
                      xLimitLine    : 3.0,
                      yLimitLine    : 0.95,
                      xAxisFormatterChoice: .none)
    }
}
