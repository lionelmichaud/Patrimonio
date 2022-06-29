//
//  Revenue.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue
import Liabilities

// MARK: - agrégat des revenus hors SCI

public struct ValuedRevenues {
    
    // MARK: - Properties

    public var name : String
    public var perCategory: [RevenueCategory: RevenuesInCategory] = [:]
    
    /// revenus imposable de l'année précédente et reporté à l'année courante
    var taxableIrppRevenueDelayedFromLastYear = Debt(name  : "REVENU IMPOSABLE REPORTE DE L'ANNEE PRECEDENTE",
                                                     note  : "",
                                                     value : 0)
    
    /// Total de tous les revenus nets de l'année versé en compte courant avant taxes et impots
    public var totalRevenue: Double {
        perCategory.reduce(.zero, { result, element in
            result + element.value.credits.total
        })
    }

    /// Total de tous les revenus nets de l'année versé en compte courant avant taxes et impots - exclus les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    var totalRevenueSalesAndCapitalizedExcluded: Double {
        perCategory.reduce(.zero, { result, element in
            if element.key.isPartOfCashFlow {
                return result + element.value.credits.total
            } else {
                return result
            }
        })
    }
    
    /// total de tous les revenus de l'année imposables à l'IRPP
    public var totalTaxableIrpp: Double {
        // ne pas oublier les revenus en report d'imposition
        perCategory.reduce(.zero, { result, element in
            result + element.value.taxablesIrpp.total
        })
        + taxableIrppRevenueDelayedFromLastYear.value(atEndOf: 0)
    }
    
    /// tableau des noms de catégories et valeurs total "créditée" des revenus de cette catégorie
    public var summary: NamedValueTable {
        var table = NamedValueTable(tableName: name)
        
        // itérer sur l'enum pour préserver l'ordre
        for category in RevenueCategory.allCases {
            if let element = perCategory[category] {
                table.namedValues.append(NamedValue(name  : element.name,
                                                    value : element.credits.total))
            }
        }
        return table
    }
    
    /// tableau détaillé des noms des revenus: concaténation à plat des catégories
    var namesFlatArray: [String] {
        var headers: [String] = [ ]
        perCategory.forEach { element in
            headers += element.value.credits.namesArray
        }
        return headers
    }

    /// tableau détaillé des valeurs des revenus: concaténation à plat des catégories
    var valuesFlatArray: [Double] {
        var values: [Double] = [ ]
        perCategory.forEach { element in
            values += element.value.credits.valuesArray
        }
        return values
    }
    
    // MARK: - Initializers

    /// Initializer toutes les catéogires (avec des tables vides de revenu)
    init(name: String) {
        self.name = name
        for category in RevenueCategory.allCases {
            perCategory[category] = RevenuesInCategory(name: category.displayString)
        }
    }
    
    // MARK: - Methods

    subscript(category : RevenueCategory) -> RevenuesInCategory? {
        get {
            return perCategory[category]
        }
        set(newValue) {
            perCategory[category] = newValue
        }
    }
    
    func namesArray(_ inCategory: RevenueCategory) -> [String]? {
        perCategory[inCategory]?.credits.namesArray
    }
    
    func valuesArray(_ inCategory: RevenueCategory) -> [Double]? {
        perCategory[inCategory]?.credits.valuesArray
    }
    
    public func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        summary.filtredNames(with : itemSelectionList)
    }
    
    public func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        summary.filtredValues(with : itemSelectionList)
    }
}

extension ValuedRevenues: CustomStringConvertible {
    public var description: String {
        let nameStr = "Nom: \(name)\n"
        var tableStr = ""
        perCategory.forEach { category, revenues in
            tableStr += "\(category.displayString) :\n"
            tableStr += "\(String(describing: revenues).withPrefixedSplittedLines("  ")) :\n"
        }
        return nameStr + tableStr
    }
}

// MARK: Agrégat de tables des revenus (perçu, taxable) pour une catégorie nommée donnée

public struct RevenuesInCategory {
    
    // MARK: - Properties

    /// nom de la catégorie de revenus
    public var name: String // category.displayString
    
    /// table des revenus versés en compte courant avant taxes, prélèvements sociaux et impots
    public var credits: NamedValueTable
    
    /// table des fractions de revenus versés en compte courant qui est imposable à l'IRPP
    var taxablesIrpp: NamedValueTable
    
    // MARK: - Initializers

    init(name: String) {
        self.name         = name
        self.credits      = NamedValueTable(tableName: name + " PERCU")
        self.taxablesIrpp = NamedValueTable(tableName: name + " TAXABLE")
    }
}

extension RevenuesInCategory: CustomStringConvertible {
    public var description: String {
        """

        Nom: \(name)
        \(credits.description.withPrefixedSplittedLines("  "))
        \(taxablesIrpp.description.withPrefixedSplittedLines("  "))
        """
    }
}

// MARK: - Extensions for VISITORS

extension ValuedRevenues: CashFlowCsvVisitableP {
    public func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension ValuedRevenues: CashFlowStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension ValuedRevenues: CashFlowCategoryStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
