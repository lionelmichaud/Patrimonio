//
//  BarChartBalanceSheetVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 14/05/2021.
//

import Foundation
import AppFoundation
import NamedValue
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Génération de graphiques - Détail d'une seule catégorie - CASH FLOW

/// Créer le DataSet pour former un un graphe barre empilées : passif / actif / net
/// - Parameters:
///   - combination: passif / actif / tout
///   - itemSelectionList: séries sélectionnées pour être affichées
/// - Returns: DataSet
class BarChartBalanceSheetVisitor: BalanceSheetStackedBarChartVisitorP {

    var dataSet: BarChartDataSet?
    private var _dataSet          = BarChartDataSet()
    private var dataEntries       = [ChartDataEntry]()
    private var personSelection   : String
    private var combination       : BalanceCombination = .both
    private var itemSelectionList : ItemSelectionList
    private var barChartDataEntry = [BarChartDataEntry]()
    private var assetSummary      = [Double]()
    private var assetLabels       = [String]()
    private var liabilitySummary  = [Double]()
    private var liabilityLabels   = [String]()
    private var processingFirstLine = false

    init(element           : BalanceSheetArray,
         personSelection   : String,
         combination       : BalanceCombination = .both,
         itemSelectionList : ItemSelectionList) {
        self.personSelection   = personSelection
        self.combination       = combination
        self.itemSelectionList = itemSelectionList
        buildStackedBarChart(element: element)
    }

    func buildStackedBarChart(element: BalanceSheetArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }

        for idx in element.startIndex..<element.endIndex {
            processingFirstLine = (idx == element.startIndex)
            element[idx].accept(self)
        }

        let labels = assetLabels + liabilityLabels
        _dataSet = BarChartDataSet(entries: dataEntries,
                                   label: (labels.count == 1 ? labels.first : nil))
        _dataSet.stackLabels = labels
        _dataSet.colors = ChartThemes.colors(numberPositive: assetLabels.count,
                                             numberNegative: liabilityLabels.count)
        dataSet = _dataSet
    }

    func buildStackedBarChart(element: BalanceSheetLine) {
        switch combination {
            case .assets:
                element.assets[personSelection]!.accept(self)
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : assetSummary))

            case .liabilities:
                element.liabilities[personSelection]!.accept(self)
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : liabilitySummary))

            case .both:
                element.assets[personSelection]!.accept(self)
                element.liabilities[personSelection]!.accept(self)
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : assetSummary + liabilitySummary))
        }
    }

    func buildStackedBarChart(element: ValuedAssets) {
        if processingFirstLine {
            assetLabels = element.summaryFiltredNames(with: itemSelectionList)
        }
        assetSummary = element.summaryFiltredValues(with: itemSelectionList)
    }

    func buildStackedBarChart(element: ValuedLiabilities) {
        if processingFirstLine {
            liabilityLabels = element.summaryFiltredNames(with: itemSelectionList)
        }
        liabilitySummary = element.summaryFiltredValues(with: itemSelectionList)
    }
}
