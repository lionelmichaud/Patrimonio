//
//  LifeExpensesDic.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import NamedValue

// MARK: - Dictionnaire de Dépenses par catégorie (un tableau de dépenses par catégorie)

public typealias LifeExpensesDic = DictionaryOfNameableValuableArray<LifeExpenseCategory, LifeExpenseArray>

public struct LifeExpenseArrayWithCategory: Identifiable {
    public var id = UUID()
    public var category: LifeExpenseCategory
    public var expenses: LifeExpenseArray
}

public typealias ArrayOfLifeExpenseArray = [LifeExpenseArrayWithCategory]

public extension LifeExpensesDic {
    func expensesInCategory(_ category: LifeExpenseCategory) -> Binding<LifeExpenseArray> {
        Binding(
            get: {
                self.perCategory[category] ?? LifeExpenseArray.empty
            },
            set: {
                self.perCategory[category] = $0
            }
        )
    }

    var categoriesOfExpenses: Binding<ArrayOfLifeExpenseArray> {
        return Binding(
            get: {
                var array = ArrayOfLifeExpenseArray()
                for category in LifeExpenseCategory.allCases {
                    array.append(LifeExpenseArrayWithCategory(category: category,
                                                              expenses: self.perCategory[category] ?? LifeExpenseArray.empty))
                }
                return array
            },
            set: {
                $0.forEach { expensesWithCategory in
                    self.perCategory[expensesWithCategory.category] = expensesWithCategory.expenses
                }
            }
        )
    }

    /// Retourne un tableau des noms des dépenses dans une catégorie donnée
    func expensesNameArray(of thisCategory: LifeExpenseCategory) -> [String] {
        var table = [String]()
        // on prend une seule catégorie
        if let expenseArray = perCategory[thisCategory] {
            let nbItem = expenseArray.items.count
            for expIdx in expenseArray.items.indices {
                table.append(expenseArray[nbItem - 1 - expIdx].name)
            }
        }
        return table
    }
    
    /// Utiliser pour générer le graphe de la vue de synthèses des dépenses
    /// - Returns: table
    func namedValuedTimeFrameTable(category: LifeExpenseCategory?)
    -> [(name : String,
         value: Double,
         prop : Bool,
         idx  : Int,
         firstYearDuration: [Int])] {
        var table = [(name: String, value: Double, prop: Bool, idx: Int, firstYearDuration: [Int])]()
        
        if category == nil {
            // on prend toutes les catégories
            var idx = 0
            perCategory.sortedReversed(by: \.key.displayString).forEach { (_, expenseArray) in
                let nbItem = expenseArray.items.count
                for expIdx in expenseArray.items.indices {
                    if let firstYear = expenseArray[nbItem - 1 - expIdx].firstYear,
                       let lastYear  = expenseArray[nbItem - 1 - expIdx].lastYear {
                        table.append((name              : expenseArray[nbItem - 1 - expIdx].name.truncate(to: 20, addEllipsis: true),
                                      value             : expenseArray[nbItem - 1 - expIdx].value,
                                      prop              : expenseArray[nbItem - 1 - expIdx].proportional,
                                      idx               : idx,
                                      firstYearDuration : [firstYear, lastYear - firstYear + 1]))
                    }
                    idx += 1
                }
            }
            
        } else {
            // on prend une seule catégorie
            var idx = 0
            if let expenseArray = perCategory[category!] {
                let nbItem = expenseArray.items.count
                for expIdx in expenseArray.items.indices {
                    if let firstYear = expenseArray[nbItem - 1 - expIdx].firstYear,
                       let lastYear  = expenseArray[nbItem - 1 - expIdx].lastYear {
                        table.append((name              : expenseArray[nbItem - 1 - expIdx].name.truncate(to: 20, addEllipsis: true),
                                      value             : expenseArray[nbItem - 1 - expIdx].value,
                                      prop              : expenseArray[nbItem - 1 - expIdx].proportional,
                                      idx               : idx,
                                      firstYearDuration : [firstYear, lastYear - firstYear + 1]))
                    }
                    idx += 1
                }
            }
        }
        
        return table
    }
}
