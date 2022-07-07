//
//  CategoryBarChartBalanceSheetVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 14/05/2021.
//

import Foundation
import os
import AppFoundation
import NamedValue
import AssetsModel
import Liabilities
import BalanceSheet
import AndroidCharts // https://github.com/danielgindi/Charts.git
import ChartsExtensions

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CategoryBarChartBalanceSheetVisitor")

/// Créer le DataSet pour former un un graphe barre empilées : une seule catégorie
/// - Parameters:
///   - categoryName: nom de la catégories
/// - Returns       : DataSet
class CategoryBarChartBalanceSheetVisitor: BalanceSheetCategoryStackedBarChartVisitorP {

    var dataSet: BarChartDataSet?
    private var _dataSet          = BarChartDataSet()
    private var dataEntries       = [ChartDataEntry]()
    private var personSelection   : String
    private var categoryName      : String
    private var combination       : BalanceCombination = .both
    private var processingFirstLine = false
    private var assetsCategory    : AssetsCategory?
    private var liabilityCategory : LiabilitiesCategory?
    private var y: [Double]?

    init(element           : BalanceSheetArray,
         personSelection   : String,
         categoryName      : String,
         combination       : BalanceCombination = .both) {
        self.personSelection   = personSelection
        self.categoryName      = categoryName
        self.combination       = combination
        self.assetsCategory    = AssetsCategory(rawValue: categoryName)
        self.liabilityCategory = LiabilitiesCategory(rawValue: categoryName)
        buildCategoryStackedBarChart(element: element)
    }

    func buildCategoryStackedBarChart(element: BalanceSheetArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }

        let firstLine = element.first!

        var nbPositiveLabels = 0
        var nbNegativeLabels = 0
        var labelsInCategory : [String]?

        if let assetsCategory = assetsCategory {
            /// rechercher les valeurs des actifs
            labelsInCategory = firstLine.assets[personSelection]!.namesArray(assetsCategory)
            if labelsInCategory == nil {
                dataSet = _dataSet
                return
            }
            nbPositiveLabels = labelsInCategory!.count
            for idx in element.startIndex..<element.endIndex {
                processingFirstLine = (idx == element.startIndex)
                element[idx].accept(self)
            }

        } else if let liabilityCategory = liabilityCategory {
            /// rechercher les valeurs des passifs
            labelsInCategory = firstLine.liabilities[personSelection]!.namesArray(liabilityCategory)
            if labelsInCategory == nil {
                dataSet = _dataSet
                return
            }
            nbNegativeLabels = labelsInCategory!.count
            for idx in element.startIndex..<element.endIndex {
                processingFirstLine = (idx == element.startIndex)
                element[idx].accept(self)
            }

        } else {
            customLog.log(level: .error, "Catégorie \(self.categoryName) NON trouvée dans balanceArray.first!")
            assert(true, "Catégorie \(categoryName) NON trouvée dans balanceArray.first!")
            dataSet = _dataSet
            return
        }

        _dataSet = BarChartDataSet(entries : dataEntries,
                                   label   : (labelsInCategory!.count == 1 ? labelsInCategory!.first : nil))
        _dataSet.stackLabels = labelsInCategory!
        _dataSet.colors      = ChartThemes.colors(numberPositive: nbPositiveLabels,
                                                  numberNegative: nbNegativeLabels)
        dataSet = _dataSet
    }

    func buildCategoryStackedBarChart(element: BalanceSheetLine) {
        if assetsCategory != nil {
            element.assets[personSelection]!.accept(self)
        } else if liabilityCategory != nil {
            element.liabilities[personSelection]!.accept(self)
        }
        guard let y = y else { return }
        dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                             yValues : y))
    }

    func buildCategoryStackedBarChart(element: ValuedAssets) {
        y = element.valuesArray(assetsCategory!)
    }

    func buildCategoryStackedBarChart(element: ValuedLiabilities) {
        y = element.valuesArray(liabilityCategory!)
    }
}
