//
//  IsfChartCashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 15/05/2021.
//

import Foundation
import AppFoundation
import CashFlow
import AndroidCharts

// MARK: - Génération de graphiques - ISF - CASH FLOW

class IsfChartCashFlowVisitor: CashFlowIsfVisitorP {

    var dataSets: [LineChartDataSet]?
    private var _dataSets = [LineChartDataSet]()
    private var yVals1    = [ChartDataEntry]()
    private var yVals2    = [ChartDataEntry]()
    private var taxable : Double = 0
    private var amount  : Double = 0

    init(element: CashFlowArray) {
        buildIsfChart(element: element)
    }

    func buildIsfChart(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }

        element.forEach { line in
            line.accept(self)
        }

        // patrimoine imposable
        let set1 = LineChartDataSet(entries : yVals1,
                                    label   : "Patrimoine Imposable",
                                    color   : #colorLiteral(red   : 0.2392156869, green   : 0.6745098233, blue   : 0.9686274529, alpha   : 1))
        set1.axisDependency = .left

        // isf
        let set2 = LineChartDataSet(entries : yVals2,
                                    label   : "ISF",
                                    color   : #colorLiteral(red   : 1, green   : 0.1491314173, blue   : 0, alpha   : 1))
        set2.axisDependency = .right

        // ajouter les dataSet au dataSets
        _dataSets.append(set1)
        _dataSets.append(set2)

        dataSets = _dataSets
    }

    func buildIsfChart(element: CashFlowLine) {
        element.adultTaxes.accept(self)
        // patrimoine imposable
        yVals1.append(ChartDataEntry(x: element.year.double(),
                                     y: taxable))
        // isf
        yVals2.append(ChartDataEntry(x: element.year.double(),
                                     y: amount))
    }

    func buildIsfChart(element: ValuedTaxes) {
        taxable = element.isf.taxable
        amount  = element.isf.amount
    }

}
