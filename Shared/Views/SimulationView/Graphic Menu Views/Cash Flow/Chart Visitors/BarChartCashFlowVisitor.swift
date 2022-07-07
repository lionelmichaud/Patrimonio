//
//  BarChartCashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 14/05/2021.
//

import Foundation
import AppFoundation
import Persistence
import NamedValue
import CashFlow
import AndroidCharts // https://github.com/danielgindi/Charts.git
import ChartsExtensions

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
    private var personSelection     : String
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
         personSelection   : String,
         combination       : CashCombination = .both,
         itemSelectionList : ItemSelectionList) {
        self.personSelection   = personSelection
        self.combination       = combination
        self.itemSelectionList = itemSelectionList
        buildStackedBarChart(element: element)
    }
    
    func buildStackedBarChart(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }
        
        positiveLabels = []
        negativeLabels = []
        
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
    
    func buildStackedBarChart(element: CashFlowLine) { // swiftlint:disable:this cyclomatic_complexity
        var revenues : ValuedRevenues
        var taxes    : ValuedTaxes
        
        if personSelection == AppSettings.shared.adultsLabel {
            revenues = element.adultsRevenues
            taxes    = element.adultTaxes
        } else {
            revenues = element.childrenRevenues
            taxes    = element.childrenTaxes
        }
        
        switch combination {
            case .revenues:
                revenues.accept(self)
                if processingFirstLine {
                    positiveLabels += labelRevenues
                }
                
                if personSelection == AppSettings.shared.adultsLabel {
                    element.sciCashFlowLine.accept(self)
                    if processingFirstLine {
                        positiveLabels += labelSCI
                    }
                }
                
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : yRevenues + ySCI))
                
            case .expenses:
                taxes.accept(self)
                if processingFirstLine {
                    negativeLabels += labelTaxes
                }
                
                if personSelection == AppSettings.shared.adultsLabel {
                    yExpenses = -element.lifeExpenses.filtredTableValue(with : itemSelectionList)
                    yDebt     = -element.debtPayements.filtredTableValue(with     : itemSelectionList)
                    yInvest   = -element.investPayements.filtredTableValue(with : itemSelectionList)
                    if processingFirstLine {
                        labelExpenses = element.lifeExpenses.filtredTableName(with: itemSelectionList)
                        labelDebt     = element.debtPayements.filtredTableName(with: itemSelectionList)
                        labelInvest   = element.investPayements.filtredTableName(with: itemSelectionList)
                        negativeLabels += labelExpenses + labelDebt + labelInvest
                    }
                }
                
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : yTaxes + yExpenses + yDebt + yInvest))
                
            case .both:
                revenues.accept(self)
                if processingFirstLine {
                    positiveLabels += labelRevenues
                }
                
                if personSelection == AppSettings.shared.adultsLabel {
                    element.sciCashFlowLine.accept(self)
                    if processingFirstLine {
                        positiveLabels += labelSCI
                    }
                }
                
                taxes.accept(self)
                if processingFirstLine {
                    negativeLabels += labelTaxes
                }
                
                if personSelection == AppSettings.shared.adultsLabel {
                    yExpenses = -element.lifeExpenses.filtredTableValue(with : itemSelectionList)
                    yDebt     = -element.debtPayements.filtredTableValue(with     : itemSelectionList)
                    yInvest   = -element.investPayements.filtredTableValue(with : itemSelectionList)
                    if processingFirstLine {
                        labelExpenses = element.lifeExpenses.filtredTableName(with: itemSelectionList)
                        labelDebt     = element.debtPayements.filtredTableName(with: itemSelectionList)
                        labelInvest   = element.investPayements.filtredTableName(with: itemSelectionList)
                        negativeLabels += labelExpenses + labelDebt + labelInvest
                    }
                }
                
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : yRevenues + ySCI + yTaxes + yExpenses + yDebt + yInvest))
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
