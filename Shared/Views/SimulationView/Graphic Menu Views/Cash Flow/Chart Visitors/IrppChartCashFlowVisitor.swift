//
//  IrppChartCashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 16/05/2021.
//

import Foundation
import AppFoundation
import Charts

// MARK: - Génération de graphiques - Synthèse - FISCALITE IRPP

/// Dessiner un graphe à lignes : revenu imposable + irpp
/// - Returns: tableau de LineChartDataSet
class IrppChartCashFlowVisitor: CashFlowIrppVisitorP {

    var dataSets: [LineChartDataSet]?
    private var _dataSets = [LineChartDataSet]()
    private var yVals1    = [ChartDataEntry]()
    private var yVals2    = [ChartDataEntry]()
    private var patrimoine : Double = 0
    private var amount     : Double = 0

    init(element: CashFlowArray) {
        buildIrppChart(element: element)
    }

    func buildIrppChart(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }
        
        element.forEach { line in
            line.accept(self)
        }

        let set1 = LineChartDataSet(entries : yVals1,
                                    label   : "Revenu Imposable",
                                    color   : #colorLiteral(red   : 0.2392156869, green   : 0.6745098233, blue   : 0.9686274529, alpha   : 1))
        let set2 = LineChartDataSet(entries : yVals2,
                                    label   : "IRPP",
                                    color   : #colorLiteral(red   : 1, green   : 0.1491314173, blue   : 0, alpha   : 1))

        // ajouter les dataSet au dataSets
        _dataSets.append(set1)
        _dataSets.append(set2)

        dataSets = _dataSets
    }

    func buildIrppChart(element: CashFlowLine) {
        element.adultTaxes.accept(self)
        // patrimoine imposable
        yVals1.append(ChartDataEntry(x: element.year.double(),
                                     y: patrimoine))
        // isf
        yVals2.append(ChartDataEntry(x: element.year.double(),
                                     y: amount))
    }

    func buildIrppChart(element: ValuedTaxes) {
        patrimoine = element.irpp.amount / element.irpp.averageRate
        amount     = element.irpp.amount
    }
}
