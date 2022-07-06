//
//  LineChartHistogramVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 16/05/2021.
//

import Foundation
import Statistics
import AndroidCharts

// MARK: - Génération de graphiques - HISTOGRAM

/// Création des DataSet d'un Historgramme contenant:
///   une courbe de la densité de probabilité PDF
///   une courbe de la densité de probabilité cumulée CDF
/// - Parameter histogram: Histogramme
/// - Returns: 2 x dataSet
class LineChartHistogramVisitor: HistogramChartVisitorP {

    var dataSets = [LineChartDataSet]()
    //: ### ChartDataEntry
    private var yVals1 = [ChartDataEntry]()
    private var yVals2 = [ChartDataEntry]()

    init(element: Histogram) {
        buildChart(element: element)
    }

    func buildChart(element: Histogram) {
        /// Distribution des échantillons en % de la case la plus remplie
        let maxCount = element.counts.max()!.double()
        element.xCounts.forEach {
            yVals1.append(ChartDataEntry(x: $0.x, y: $0.n.double() / maxCount))
        }

        /// CDF des échantillons
        element.xCDF.forEach {
            yVals2.append(ChartDataEntry(x: $0.x, y: $0.p))
        }

        let set1 = LineChartDataSet(entries   : yVals1,
                                    label     : "PDF " + element.name,
                                    color     : #colorLiteral(red     : 0.6000000238, green     : 0.6000000238, blue     : 0.6000000238, alpha     : 1),
                                    lineWidth : 0.5)
        set1.axisDependency = .left

        let set2 = LineChartDataSet(entries : yVals2,
                                    label   : "CDF " + element.name,
                                    color   : #colorLiteral(red   : 0.721568644, green   : 0.8862745166, blue   : 0.5921568871, alpha   : 1))
        set2.axisDependency = .left

        // ajouter les dataSet au dataSets
        dataSets.append(set1)
        dataSets.append(set2)
    }
}
