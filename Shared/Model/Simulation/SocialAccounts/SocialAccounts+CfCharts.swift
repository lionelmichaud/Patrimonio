//
//  SocialAccounts+Charts.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif
import AppFoundation
import NamedValue
import Charts // https://github.com/danielgindi/Charts.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts+CfCharts")

// MARK: - Extension de SocialAccounts pour graphiques CASH FLOW

extension SocialAccounts {
    
    // MARK: - Génération de graphiques - Détail d'une seule catégorie - CASH FLOW
    
    /// Créer le DataSet pour former un un graphe barre empilées : une seule catégorie
    /// - Parameters:
    ///   - categoryName: nom de la catégories
    /// - Returns: DataSet
    func getCashFlowCategoryStackedBarChartDataSet(categoryName            : String,
                                                   expenses                : LifeExpensesDic,
                                                   selectedExpenseCategory : LifeExpenseCategory? = nil) -> BarChartDataSet? {
        
        /// rechercher la catégorie dans les revenus
        func getRevenusDataSet() -> BarChartDataSet {
            // customLog.log(level: .info, "Catégorie trouvée dans Revenues : \(found.name)")
            guard let category = RevenueCategory(rawValue: categoryName) else {
                return BarChartDataSet()
            }
            // print("  nom : \(category)")
            guard let labelsInCategory = firstLine.revenues.perCategory[category]?.credits.namesArray else {
                return BarChartDataSet()
            }
            // print("  legende : ", labelsInCategory)
            
            // valeurs des revenus de la catégorie
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.revenues.perCategory[category]?.credits.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : y!)
            }
            let dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.positiveColors(number : dataSet.stackLabels.count)
            
            return dataSet
        }
        
        func getExpensesDataSet() -> BarChartDataSet {
            var labelsInCategory: [String]
            if let expenseCategory = selectedExpenseCategory {
                /// rechercher les valeurs de la seule catégorie de dépenses sélectionnée
                let selectedExpensesNameArray = expenses.expensesNameArray(of: expenseCategory)
                labelsInCategory = firstLine.lifeExpenses.namesArray.filter { name in
                    selectedExpensesNameArray.contains(name)
                }
                
                // valeurs des dépenses
                dataEntries = cashFlowArray.map { cashFlowLine in// pour chaque année
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
                dataEntries = cashFlowArray.map { // pour chaque année
                    let y = $0.lifeExpenses.valuesArray
                    return BarChartDataEntry(x       : $0.year.double(),
                                             yValues : -y)
                }
            }
            let dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.negativeColors(number : dataSet.stackLabels.count)

            return dataSet
        }
        
        // si la table est vide alors quitter
        guard !cashFlowArray.isEmpty else {
            return nil
        }
        
        let firstLine   = cashFlowArray.first!
        var dataEntries = [ChartDataEntry]()
        let dataSet : BarChartDataSet
        
        if firstLine.revenues.summary.namedValues.contains(where: { $0.name == categoryName }) {
            // rechercher la catégorie dans les revenus
            dataSet = getRevenusDataSet()
            
        } else if firstLine.sciCashFlowLine.summary.namedValues.contains(where: { $0.name == categoryName }) {
            /// rechercher la catégorie dans les revenus de la SCI
            // customLog.log(level: .info, "Catégorie trouvée dans sciCashFlowLine : \(found.name)")
            let labelsInCategory = firstLine.sciCashFlowLine.namesFlatArray
            
            // valeurs des dettes
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.sciCashFlowLine.valuesFlatArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : y)
            }
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.positiveColors(number : dataSet.stackLabels.count)
            
        } else if firstLine.taxes.summary.namedValues.contains(where: { $0.name == categoryName }) {
            /// rechercher les valeurs des taxes
            // customLog.log(level: .info, "Catégorie trouvée dans taxes : \(found.name)")
            guard let category = TaxeCategory(rawValue: categoryName) else {
                return BarChartDataSet()
            }
            guard let labelsInCategory = firstLine.taxes.perCategory[category]?.namesArray else {
                return BarChartDataSet()
            }
            
            // valeurs des revenus de la catégorie
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.taxes.perCategory[category]?.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y!)
            }
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.negativeColors(number : dataSet.stackLabels.count)
            
        } else if categoryName == firstLine.lifeExpenses.tableName {
            // rechercher les dépenses
            dataSet = getExpensesDataSet()
            
        } else if categoryName == firstLine.debtPayements.tableName {
            /// rechercher les valeurs des debtPayements
            // customLog.log(level: .info, "Catégorie trouvée dans debtPayements : \(categoryName)")
            let labelsInCategory = firstLine.debtPayements.namesArray
            
            // valeurs des dettes
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.debtPayements.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y)
            }
            
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.negativeColors(number : dataSet.stackLabels.count)
            
        } else if categoryName == firstLine.investPayements.tableName {
            /// rechercher les valeurs des investPayements
            // customLog.log(level: .info, "Catégorie trouvée dans investPayements : \(categoryName)")
            let labelsInCategory = firstLine.investPayements.namesArray
            
            // valeurs des investissements
            dataEntries = cashFlowArray.map { // pour chaque année
                let y = $0.investPayements.valuesArray
                return BarChartDataEntry(x       : $0.year.double(),
                                         yValues : -y)
            }
            
            dataSet = BarChartDataSet(entries : dataEntries,
                                      label   : (labelsInCategory.count == 1 ? labelsInCategory.first : nil))
            dataSet.stackLabels = labelsInCategory
            dataSet.colors      = ChartThemes.negativeColors(number : dataSet.stackLabels.count)
            
        } else {
            customLog.log(level: .error, "Catégorie \(categoryName) NON trouvée dans cashFlowArray.first!")
            dataSet = BarChartDataSet()
        }
        
        return dataSet
    }
}
