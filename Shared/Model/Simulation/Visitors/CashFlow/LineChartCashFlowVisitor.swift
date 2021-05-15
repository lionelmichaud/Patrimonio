//
//  LineChartCashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 14/05/2021.
//

import Foundation
import AppFoundation
import Charts

// MARK: - Génération de graphiques - Synthèse - CASH FLOW

/// Dessiner un graphe à lignes : revenus + dépenses + net
/// - Returns: UIView
class LineChartCashFlowVisitor: CashFlowLineChartVisitorP {
    init(element: CashFlowArray) {
        buildLineChart(element: element)
    }

    var dataSets = [LineChartDataSet]()
    //: ### ChartDataEntry
    private var yVals1 = [ChartDataEntry]()
    private var yVals2 = [ChartDataEntry]()
    private var yVals3 = [ChartDataEntry]()
    private var totalAssetsValue      : Double = 0
    private var totalLiabilitiesValue : Double = 0

    func buildLineChart(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }

        element.forEach {
            $0.accept(self)
        }

        let set1 = LineChartDataSet(entries: yVals1,
                                    label: "Actif",
                                    color: #colorLiteral(red        : 0.4666666687, green        : 0.7647058964, blue        : 0.2666666806, alpha        : 1))
        let set2 = LineChartDataSet(entries: yVals2,
                                    label: "Passif",
                                    color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
        let set3 = LineChartDataSet(entries: yVals3,
                                    label: "Net",
                                    color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))

        // ajouter les dataSet au dataSets
        self.dataSets.append(set1)
        self.dataSets.append(set2)
        self.dataSets.append(set3)
    }

    func buildLineChart(element: CashFlowLine) {
        self.yVals1.append(ChartDataEntry(x: element.year.double(),
                                          y: element.sumOfRevenues))
        self.yVals2.append(ChartDataEntry(x: element.year.double(),
                                          y: -element.sumOfExpenses))
        self.yVals3.append(ChartDataEntry(x: element.year.double(),
                                          y: element.netCashFlow))
    }

}
