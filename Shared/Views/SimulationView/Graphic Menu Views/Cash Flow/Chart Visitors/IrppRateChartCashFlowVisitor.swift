//
//  IrppRateChartCashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 16/05/2021.
//

import Foundation
import AppFoundation
import Charts

/// Dessiner un graphe à lignes : taux d'imposition marginal + taux d'imposition moyen
/// Dessiner un graphe à barres : quotient familial
/// - Returns: tableau de LineChartDataSet
class IrppRateChartCashFlowVisitor: CashFlowIrppRateVisitorP {

    var lineDataSets : [LineChartDataSet]?
    var barDataSets  : [BarChartDataSet]?
    private var _lineDataSets = [LineChartDataSet]()
    private var _barDataSets  = [BarChartDataSet]()
    private var yLineVals1    = [ChartDataEntry]()
    private var yLineVals2    = [ChartDataEntry]()
    private var yBarVals1     = [ChartDataEntry]()
    private var averageRate    : Double = 0
    private var marginalRate   : Double = 0
    private var familyQuotient : Double = 0

    init(element: CashFlowArray) {
        buildIrppRateChart(element: element)
    }

    func buildIrppRateChart(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }

        element.forEach { line in
            line.accept(self)
        }

        let lineSet1 = LineChartDataSet(entries: yLineVals1,
                                        label: "Taux Moyen",
                                        color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        lineSet1.axisDependency = .left
        lineSet1.lineWidth      = 3.0
        let lineSet2 = LineChartDataSet(entries: yLineVals2,
                                        label: "Taux Marginal",
                                        color: #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1))
        lineSet2.axisDependency = .left
        lineSet2.lineWidth      = 3.0

        // ajouter les dataSet au dataSets
        _lineDataSets.append(lineSet1)
        _lineDataSets.append(lineSet2)

        lineDataSets = _lineDataSets

        let barSet1 = BarChartDataSet(entries : yBarVals1,
                                      label   : "Quotient Familial")
        barSet1.setColor(#colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1))
        barSet1.axisDependency    = .right
        barSet1.drawValuesEnabled = false

        // ajouter les dataSet au dataSets
        _barDataSets.append(barSet1)

        barDataSets = _barDataSets
    }

    func buildIrppRateChart(element: CashFlowLine) {
        element.taxes.accept(self)
        // taux moyen
        yLineVals1.append(ChartDataEntry(x: element.year.double(),
                                         y: averageRate))
        // taux marginal
        yLineVals2.append(ChartDataEntry(x: element.year.double(),
                                         y: marginalRate))
        // quotient familial
        yBarVals1.append(BarChartDataEntry(x: element.year.double(),
                                           y: familyQuotient))
    }

    func buildIrppRateChart(element: ValuedTaxes) {
        averageRate    = element.irpp.averageRate
        marginalRate   = element.irpp.marginalRate
        familyQuotient = element.irpp.familyQuotient
    }
}
