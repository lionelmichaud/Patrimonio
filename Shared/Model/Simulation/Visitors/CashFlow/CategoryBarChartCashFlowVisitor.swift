//
//  CategoryBarChartCashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 15/05/2021.
//

import Foundation
import os
import AppFoundation
import NamedValue
import Charts // https://github.com/danielgindi/Charts.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CategoryBarChartCashFlowVisitor")

/// Créer le DataSet pour former un un graphe barre empilées : une seule catégorie
/// - Parameters:
///   - categoryName: nom de la catégories
/// - Returns       : DataSet
class CategoryBarChartCashFlowVisitor: CashFlowCategoryStackedBarChartVisitorP {

    var dataSet                         : BarChartDataSet?
    private var _dataSet                = BarChartDataSet()
    private var dataEntries             = [ChartDataEntry]()
    private var categoryName            : String
    private var expenses                : LifeExpensesDic
    private var selectedExpenseCategory : LifeExpenseCategory?
    private var revenueCategory         : RevenueCategory?
    private var labelsInCategory        = [String]()
    private var processingFirstLine = false
    private var year = 0
    private var y: [Double]?

    init(element                 : CashFlowArray,
         categoryName            : String,
         expenses                : LifeExpensesDic,
         selectedExpenseCategory : LifeExpenseCategory?  = nil) {
        self.categoryName            = categoryName
        self.expenses                = expenses
        self.selectedExpenseCategory = selectedExpenseCategory
        self.revenueCategory         = RevenueCategory(rawValue: categoryName)
        buildCategoryStackedBarChart(element: element)
    }

    func buildCategoryStackedBarChart(element: CashFlowArray) {
        /// rechercher la catégorie dans les revenus
        var nbPositiveLabels = 0
        var nbNegativeLabels = 0

        func getExpensesDataSet() {
            if let expenseCategory = selectedExpenseCategory {
                /// rechercher les valeurs de la seule catégorie de dépenses sélectionnée
                let selectedExpensesNameArray = expenses.expensesNameArray(of: expenseCategory)
                labelsInCategory = firstLine.lifeExpenses.namesArray.filter { name in
                    selectedExpensesNameArray.contains(name)
                }

                // valeurs des dépenses
                dataEntries = element.map { cashFlowLine in// pour chaque année
                    let selectedNamedValues = cashFlowLine.lifeExpenses.namedValues
                        .filter({ (name, _) in
                            selectedExpensesNameArray.contains(name)
                        })
                    let y = selectedNamedValues.map(\.value)
                    return BarChartDataEntry(x       : cashFlowLine.year.double(),
                                             yValues : -y)
                }

            } else {
                /// rechercher les valeurs de toutes les dépenses
                // customLog.log(level: .info, "Catégorie trouvée dans lifeExpenses : \(categoryName)")
                labelsInCategory = firstLine.lifeExpenses.namesArray

                // valeurs des dépenses
                dataEntries = element.map { // pour chaque année
                    let y = $0.lifeExpenses.valuesArray
                    return BarChartDataEntry(x       : $0.year.double(),
                                             yValues : -y)
                }
            }
            nbNegativeLabels = labelsInCategory.count
        }

        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }

        let firstLine = element.first!

        if firstLine.revenues.summary.contains(name: categoryName) {
            /// rechercher la catégorie dans les revenus
            for idx in element.startIndex..<element.endIndex {
                processingFirstLine = (idx == element.startIndex)
                year = element[idx].year
                element[idx].revenues.accept(self)
            }
            nbPositiveLabels = labelsInCategory.count

        } else if firstLine.sciCashFlowLine.summary.contains(name: categoryName) {
            /// rechercher la catégorie dans les revenus de la SCI
            // customLog.log(level: .info, "Catégorie trouvée dans sciCashFlowLine : \(found.name)")
            labelsInCategory = firstLine.sciCashFlowLine.namesFlatArray

            // valeurs des dettes
            dataEntries = element.map { // pour chaque année
                let y = $0.sciCashFlowLine.valuesFlatArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : y)
            }
            nbPositiveLabels = labelsInCategory.count

        } else if firstLine.taxes.summary.contains(name: categoryName) {
            /// rechercher les valeurs des taxes
            // customLog.log(level: .info, "Catégorie trouvée dans taxes : \(found.name)")
            guard let category = TaxeCategory(rawValue: categoryName) else {
                dataSet = _dataSet
                return
            }
            guard let labels = firstLine.taxes.perCategory[category]?.namesArray else {
                dataSet = _dataSet
                return
            }
            labelsInCategory = labels

            // valeurs des revenus de la catégorie
            dataEntries = element.map { // pour chaque année
                let y = $0.taxes.perCategory[category]?.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y!)
            }
            nbNegativeLabels = labelsInCategory.count

        } else if categoryName == firstLine.lifeExpenses.tableName {
            /// rechercher les dépenses
            getExpensesDataSet()

        } else if categoryName == firstLine.debtPayements.tableName {
            /// rechercher les valeurs des debtPayements
            // customLog.log(level: .info, "Catégorie trouvée dans debtPayements : \(categoryName)")
            labelsInCategory = firstLine.debtPayements.namesArray

            // valeurs des dettes
            dataEntries = element.map { // pour chaque année
                let y = $0.debtPayements.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y)
            }

            nbNegativeLabels = labelsInCategory.count

        } else if categoryName == firstLine.investPayements.tableName {
            /// rechercher les valeurs des investPayements
            // customLog.log(level: .info, "Catégorie trouvée dans investPayements : \(categoryName)")
            labelsInCategory = firstLine.investPayements.namesArray

            // valeurs des investissements
            dataEntries = element.map { // pour chaque année
                let y = $0.investPayements.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y)
            }

            nbNegativeLabels = labelsInCategory.count

        } else {
            customLog.log(level: .error, "Catégorie \(self.categoryName) NON trouvée dans element.first!")
            dataSet = _dataSet
            return
        }

        _dataSet = BarChartDataSet(entries : dataEntries,
                                   label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
        _dataSet.stackLabels = labelsInCategory
        _dataSet.colors      = ChartThemes.colors(numberPositive: nbPositiveLabels,
                                                  numberNegative: nbNegativeLabels)
        dataSet = _dataSet
    }

    func buildCategoryStackedBarChart(element: CashFlowLine) {
    }

    func buildCategoryStackedBarChart(element: ValuedTaxes) {

    }

    func buildCategoryStackedBarChart(element: ValuedRevenues) {
        guard revenueCategory != nil else {
            return
        }
        if processingFirstLine {
            guard let labels = element.perCategory[revenueCategory!]?.credits.namesArray else {
                return
            }
            labelsInCategory = labels
        }
        if let y = element.perCategory[revenueCategory!]?.credits.valuesArray {
            dataEntries.append(BarChartDataEntry(x       : year.double(),
                                                 yValues : y))
        }
    }

    func buildCategoryStackedBarChart(element: SciCashFlowLine) {

    }

    func buildCategoryStackedBarChart(element: SciCashFlowLine.Revenues) {

    }

}
