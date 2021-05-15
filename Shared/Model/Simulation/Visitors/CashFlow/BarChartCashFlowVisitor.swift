//
//  BarChartCashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 14/05/2021.
//

import Foundation
import AppFoundation
import NamedValue
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Génération de graphiques - Détail par catégories - CASH FLOW

/// Créer le DataSet pour former un un graphe barre empilées : revenus / dépenses / tout
/// - Parameters:
///   - combination: revenus / dépenses / tout
///   - itemSelectionList: séries sélectionnées pour être affichées
/// - Returns: DataSet
class BarChartCashFlowVisitor: CashFlowStackedBarChartVisitorP {

    var dataSet: BarChartDataSet?
    private var _dataSet          = BarChartDataSet()
    private var dataEntries         = [ChartDataEntry]()
    private var combination         : CashCombination = .both
    private var itemSelectionList   : ItemSelectionList
    private var barChartDataEntry   = [BarChartDataEntry]()
    private var processingFirstLine = false
    private var yRevenues           = [Double]()
    private var ySCI                = [Double]()
    private var yExpenses           = [Double]()
    private var yTaxes              = [Double]()
    private var yDebt               = [Double]()
    private var yInvest             = [Double]()
    private var labelRevenues       = [String]()
    private var labelSCI            = [String]()
    private var labelExpenses       = [String]()
    private var labelTaxes          = [String]()
    private var labelDebt           = [String]()
    private var labelInvest         = [String]()
    private var positiveLabels      = [String]()
    private var negativeLabels      = [String]()

    init(element           : CashFlowArray,
         combination       : CashCombination = .both,
         itemSelectionList : ItemSelectionList) {
        self.combination       = combination
        self.itemSelectionList = itemSelectionList
        buildStackedBarChart(element: element)
    }

    func buildStackedBarChart(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }

        for idx in element.startIndex..<element.endIndex {
            processingFirstLine = (idx == element.startIndex)
            element[idx].accept(self)
        }

        let labels = positiveLabels + negativeLabels
        _dataSet = BarChartDataSet(entries: dataEntries,
                                   label: (labels.count == 1 ? labels.first : nil))
        _dataSet.stackLabels = labels
        _dataSet.colors = ChartThemes.colors(numberPositive: positiveLabels.count,
                                             numberNegative: negativeLabels.count)
        dataSet = _dataSet
    }

    func buildStackedBarChart(element: CashFlowLine) {
        switch combination {
            case .revenues:
                element.revenues.accept(self)
                element.sciCashFlowLine.accept(self)
                if processingFirstLine {
                    positiveLabels = labelRevenues + labelSCI
                }
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : yRevenues + ySCI))

            case .expenses:
                element.taxes.accept(self)
                yExpenses = -element.lifeExpenses.filtredTableValue(with : itemSelectionList)
                yDebt     = -element.debtPayements.filtredTableValue(with     : itemSelectionList)
                yInvest   = -element.investPayements.filtredTableValue(with : itemSelectionList)
                if processingFirstLine {
                    labelExpenses = element.lifeExpenses.filtredTableName(with: itemSelectionList)
                    labelDebt     = element.debtPayements.filtredTableName(with: itemSelectionList)
                    labelInvest   = element.investPayements.filtredTableName(with: itemSelectionList)
                    negativeLabels = labelExpenses + labelTaxes + labelDebt + labelInvest
                }
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : yExpenses + yTaxes + yDebt + yInvest))

            case .both:
                element.revenues.accept(self)
                element.sciCashFlowLine.accept(self)
                element.taxes.accept(self)
                yExpenses = -element.lifeExpenses.filtredTableValue(with : itemSelectionList)
                yDebt     = -element.debtPayements.filtredTableValue(with     : itemSelectionList)
                yInvest   = -element.investPayements.filtredTableValue(with : itemSelectionList)
                if processingFirstLine {
                    positiveLabels = labelRevenues + labelSCI
                    labelExpenses = element.lifeExpenses.filtredTableName(with: itemSelectionList)
                    labelDebt     = element.debtPayements.filtredTableName(with: itemSelectionList)
                    labelInvest   = element.investPayements.filtredTableName(with: itemSelectionList)
                    negativeLabels = labelExpenses + labelTaxes + labelDebt + labelInvest
                }
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : yRevenues + ySCI + yExpenses + yTaxes + yDebt + yInvest))
        }
    }

    func buildStackedBarChart(element: ValuedRevenues) {
        if processingFirstLine {
            labelRevenues = element.summaryFiltredNames(with: itemSelectionList)
        }
        yRevenues = element.summaryFiltredValues(with: itemSelectionList)
    }

    func buildStackedBarChart(element: ValuedTaxes) {
        if processingFirstLine {
            labelTaxes = element.summaryFiltredNames(with: itemSelectionList)
        }
       yTaxes = -element.summaryFiltredValues(with: itemSelectionList)
    }

    func buildStackedBarChart(element: SciCashFlowLine) {
        if processingFirstLine {
            labelSCI = element.summaryFiltredNames(with: itemSelectionList)
        }
        ySCI = element.summaryFiltredValues(with: itemSelectionList)
    }
}
