//
//  LineChartBalanceSheetVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 14/05/2021.
//

import Foundation
import AppFoundation
import Charts

// MARK: - Génération de graphiques - Détail par catégories - BALANCE SHEET

/// Dessiner un graphe à lignes : passif + actif + net
/// - Returns: UIView
class LineChartBalanceSheetVisitor: BalanceSheetLineChartVisitorP {
    
    var dataSets = [LineChartDataSet]()
    //: ### ChartDataEntry
    private var personSelection : String
    private var yVals1 = [ChartDataEntry]()
    private var yVals2 = [ChartDataEntry]()
    private var yVals3 = [ChartDataEntry]()
    private var totalAssetsValue      : Double = 0
    private var totalLiabilitiesValue : Double = 0

    init(element         : BalanceSheetArray,
         personSelection : String) {
        self.personSelection = personSelection
        buildLineChart(element: element)
    }
    
    func buildLineChart(element: BalanceSheetArray) {
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
    
    func buildLineChart(element: BalanceSheetLine) {
        element.assets[personSelection]!.accept(self)
        element.liabilities[personSelection]!.accept(self)

        self.yVals1.append(ChartDataEntry(x: element.year.double(),
                                          y: totalAssetsValue))
        self.yVals2.append(ChartDataEntry(x: element.year.double(),
                                          y: totalLiabilitiesValue))
        self.yVals3.append(ChartDataEntry(x: element.year.double(),
                                          y: totalAssetsValue + totalLiabilitiesValue))
    }
    
    func buildLineChart(element: ValuedAssets) {
        totalAssetsValue = element.total
    }
    
    func buildLineChart(element: ValuedLiabilities) {
        totalLiabilitiesValue = element.total
    }
}
