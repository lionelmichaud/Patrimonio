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
import Persistence
import LifeExpense
import CashFlow
import Charts // https://github.com/danielgindi/Charts.git
import ChartsExtensions

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CategoryBarChartCashFlowVisitor")

// MARK: - Génération de graphiques - Détail d'une seule catégorie - CASH FLOW

/// Créer le DataSet pour former un graphe barre empilées : une seule catégorie
/// - Parameters:
///   - categoryName: nom de la catégories
/// - Returns: DataSet
class CategoryBarChartCashFlowVisitor: CashFlowCategoryStackedBarChartVisitorP {

    var dataSet                         : BarChartDataSet?
    private var _dataSet                = BarChartDataSet()
    private var dataEntries             = [ChartDataEntry]()
    private var personSelection         : String
    private var categoryName            : String
    private var expenses                : LifeExpensesDic
    private var selectedExpenseCategory : LifeExpenseCategory?
    private var revenueCategory         : RevenueCategory?
    private var taxCategory             : TaxeCategory?
    private var labelsInCategory        = [String]()
    private var year                    = 0
    private var y                       : [Double]?
    private var nbPositiveLabels        = 0
    private var nbNegativeLabels        = 0

    init(element                 : CashFlowArray,
         personSelection         : String,
         categoryName            : String,
         expenses                : LifeExpensesDic,
         selectedExpenseCategory : LifeExpenseCategory?  = nil) {
        self.personSelection         = personSelection
        self.categoryName            = categoryName
        self.expenses                = expenses
        self.selectedExpenseCategory = selectedExpenseCategory
        self.revenueCategory         = RevenueCategory(rawValue: categoryName)
        self.taxCategory             = TaxeCategory(rawValue: categoryName)
        buildCategoryStackedBarChart(element: element)
    }

    func buildCategoryStackedBarChart(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else { return }

        element.forEach { $0.accept(self) }

        _dataSet = BarChartDataSet(entries : dataEntries,
                                   label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
        _dataSet.stackLabels = labelsInCategory
        _dataSet.colors      = ChartThemes.colors(numberPositive: nbPositiveLabels,
                                                  numberNegative: nbNegativeLabels)
        dataSet = _dataSet
    }

    // swiftlint:disable cyclomatic_complexity
    func buildCategoryStackedBarChart(element: CashFlowLine) {
        var revenues : ValuedRevenues
        var taxes    : ValuedTaxes
        
        if personSelection == AppSettings.shared.adultsLabel {
            revenues = element.adultsRevenues
            taxes    = element.adultTaxes
        } else {
            revenues = element.childrenRevenues
            taxes    = element.childrenTaxes
        }
        
        if revenues.summary.contains(name: categoryName) {
            /// rechercher la catégorie dans les revenus
            guard revenueCategory != nil else {
                return
            }
            if labelsInCategory.count == 0 {
                guard let labels = revenues.perCategory[revenueCategory!]?.credits.namesArray else {
                    return
                }
                labelsInCategory = labels
                nbPositiveLabels = labelsInCategory.count
            }
            revenues.accept(self)
            guard let y = y else { return }
            dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                 yValues : y))

        } else if element.sciCashFlowLine.summary.contains(name: categoryName) {
            /// rechercher la catégorie dans les revenus de la SCI
            if labelsInCategory.count == 0 {
                labelsInCategory = element.sciCashFlowLine.namesFlatArray
                nbPositiveLabels = labelsInCategory.count
            }
            // valeurs des dettes
            if personSelection == AppSettings.shared.adultsLabel {
                element.sciCashFlowLine.accept(self)
                guard let y = y else { return }
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : y))
            } else {
                let y = [Double].init(repeating: 0, count: nbPositiveLabels)
                dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                     yValues : y))
            }

        } else if taxes.summary.contains(name: categoryName) {
            /// rechercher les valeurs des taxes
            // customLog.log(level: .info, "Catégorie trouvée dans taxes : \(found.name)")
            guard taxCategory != nil else {
                return
            }
            if labelsInCategory.count == 0 {
                guard let labels = taxes.perCategory[taxCategory!]?.namesArray else {
                    return
                }
                labelsInCategory = labels
                nbNegativeLabels = labelsInCategory.count
            }
            // valeurs des revenus de la catégorie
            taxes.accept(self)
            guard let y = y else { return }
            dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                 yValues : -y))

        } else if categoryName == element.lifeExpenses.tableName {
            /// rechercher les dépenses
            getExpensesDataSet(element: element)

        } else if categoryName == element.debtPayements.tableName {
            /// rechercher les valeurs des debtPayements
            if labelsInCategory.count == 0 {
                labelsInCategory = element.debtPayements.namesArray
                nbNegativeLabels = labelsInCategory.count
            }
            // valeurs des dettes
            var y : [Double]
            if personSelection == AppSettings.shared.adultsLabel {
                y = element.debtPayements.valuesArray
            } else {
                y = [Double].init(repeating: 0, count: nbNegativeLabels)
            }
            dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                 yValues : -y))

        } else if categoryName == element.investPayements.tableName {
            /// rechercher les valeurs des investPayements
            // customLog.log(level: .info, "Catégorie trouvée dans investPayements : \(categoryName)")
            if labelsInCategory.count == 0 {
                labelsInCategory = element.investPayements.namesArray
                nbNegativeLabels = labelsInCategory.count
            }
            // valeurs des investissements
            var y : [Double]
            if personSelection == AppSettings.shared.adultsLabel {
                y = element.investPayements.valuesArray
            } else {
                y = [Double].init(repeating: 0, count: nbNegativeLabels)
            }
            dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                 yValues : -y))

        } else {
            customLog.log(level: .error, "Catégorie \(self.categoryName) NON trouvée dans element.first!")
            dataSet = _dataSet
            return
        }
    }
    // swiftlint:enable cyclomatic_complexity

    func getExpensesDataSet(element: CashFlowLine) {
        if let expenseCategory = selectedExpenseCategory {
            /// rechercher les valeurs de la seule catégorie de dépenses sélectionnée
            let selectedExpensesNameArray = expenses.expensesNameArray(of: expenseCategory)
            if labelsInCategory.count == 0 {
                labelsInCategory = element.lifeExpenses.namesArray.filter { name in
                    selectedExpensesNameArray.contains(name)
                }
            }
            
            // valeurs des dépenses
            var y : [Double]
            if personSelection == AppSettings.shared.adultsLabel {
                let selectedNamedValues = element.lifeExpenses.namedValues
                    .filter({ namedValue in
                        selectedExpensesNameArray.contains(namedValue.name)
                    })
                y = selectedNamedValues.map(\.value)
            } else {
                y = [Double].init(repeating: 0, count: labelsInCategory.count)
            }
            dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                 yValues : -y))
            
        } else {
            /// rechercher les valeurs de toutes les dépenses
            if labelsInCategory.count == 0 {
                labelsInCategory = element.lifeExpenses.namesArray
            }
            
            // valeurs des dépenses
            var y : [Double]
            if personSelection == AppSettings.shared.adultsLabel {
                y = element.lifeExpenses.valuesArray
            } else {
                y = [Double].init(repeating: 0, count: labelsInCategory.count)
            }
            dataEntries.append(BarChartDataEntry(x       : element.year.double(),
                                                 yValues : -y))
        }
        nbNegativeLabels = labelsInCategory.count
    }
    
    func buildCategoryStackedBarChart(element: ValuedTaxes) {
        y = element.perCategory[taxCategory!]?.valuesArray
    }

    func buildCategoryStackedBarChart(element: ValuedRevenues) {
        y = element.perCategory[revenueCategory!]?.credits.valuesArray
    }

    func buildCategoryStackedBarChart(element: SciCashFlowLine) {
        y = element.valuesFlatArray
    }
}
