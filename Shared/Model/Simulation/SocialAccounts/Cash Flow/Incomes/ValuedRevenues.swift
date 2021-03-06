//
//  Revenue.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue

// MARK: - agrégat des revenus hors SCI

struct ValuedRevenues {
    
    // MARK: - Properties

    var name : String
    var perCategory: [RevenueCategory: RevenuesInCategory] = [:]
    
    /// revenus imposable de l'année précédente et reporté à l'année courante
    var taxableIrppRevenueDelayedFromLastYear = Debt(name: "REVENU IMPOSABLE REPORTE DE L'ANNEE PRECEDENTE", note: "", value: 0)
    
    /// total de tous les revenus nets de l'année versé en compte courant avant taxes et impots
    var totalRevenue: Double {
        perCategory.reduce(.zero, { result, element in
            result + element.value.credits.total
        })
    }

    /// total de tous les revenus nets de l'année versé en compte courant avant taxes et impots
    var totalRevenueSalesExcluded: Double {
        perCategory.reduce(.zero, { result, element in
            if element.key.isPartOfCashFlow {
                return result + element.value.credits.total
            } else {
                return result
            }
        })
    }

    /// total de tous les revenus de l'année imposables à l'IRPP
    var totalTaxableIrpp: Double {
        // ne pas oublier les revenus en report d'imposition
        perCategory.reduce(.zero, { result, element in result + element.value.taxablesIrpp.total })
            + taxableIrppRevenueDelayedFromLastYear.value(atEndOf: 0)
    }

    /// tableau des noms de catégories et valeurs total "créditée" des revenus de cette catégorie
    var summary: NamedValueTable {
        var table = NamedValueTable(tableName: name)
        
        // itérer sur l'enum pour préserver l'ordre
        for category in RevenueCategory.allCases {
            if let element = perCategory[category] {
                table.namedValues.append((name  : element.name,
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

    func headersCSV(_ inCategory: RevenueCategory) -> String? {
        perCategory[inCategory]?.credits.headerCSV
    }
    
    func valuesCSV(_ inCategory: RevenueCategory) -> String? {
        perCategory[inCategory]?.credits.valuesCSV
    }
    
    func namesArray(_ inCategory: RevenueCategory) -> [String]? {
        perCategory[inCategory]?.credits.namesArray
    }
    
    func valuesArray(_ inCategory: RevenueCategory) -> [Double]? {
        perCategory[inCategory]?.credits.valuesArray
    }
    
    func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        summary.filtredNames(with : itemSelectionList)
    }
    
    func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        summary.filtredValues(with : itemSelectionList)
    }
}

// MARK: Agrégat de tables des revenus (perçu, taxable) pour une catégorie nommée donnée

struct RevenuesInCategory {
    
    // MARK: - Properties

    /// nom de la catégorie de revenus
    var name: String // category.displayString
    
    /// table des revenus versés en compte courant avant taxes, prélèvements sociaux et impots
    var credits: NamedValueTable
    
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
    var description: String {
        var desc = "Nom: \(name)\n"
        desc += credits.description.withPrefixedSplittedLines("  ") + "\n"
        desc += taxablesIrpp.description.withPrefixedSplittedLines("  ") + "\n"

        return desc
    }
}
