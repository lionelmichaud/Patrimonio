//
//  BalanceSheetLine.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/05/2021.
//

import Foundation
import NamedValue

// MARK: - Ligne de Bilan annuel

struct BalanceSheetLine {

    // MARK: - Properties

    // année de début de la simulation
    var year: Int   = 0
    // actifs
    var assets      : [String : ValuedAssets]
    // passifs
    var liabilities : [String : ValuedLiabilities]
    // net
    var netAssets   : Double {
        assets[AppSettings.shared.allPersonsLabel]!.total
            + liabilities[AppSettings.shared.allPersonsLabel]!.total
    }
    // tous les actifs net sauf immobilier physique
    var netFinancialAssets : Double {
        netAssets
            - (assets[AppSettings.shared.allPersonsLabel]!.perCategory[.realEstates]?.total ?? 0)
    }
    // tous les actifs sauf immobilier physique
    var financialAssets: Double {
        assets[AppSettings.shared.allPersonsLabel]!.total
            - (assets[AppSettings.shared.allPersonsLabel]!.perCategory[.realEstates]?.total ?? 0.0)
    }

    // MARK: - Initializers

    init(withYear year               : Int,
         withMembersName membersName : [String],
         withAssets assets           : [(ownable: Ownable, category: AssetsCategory)],
         withLiabilities liabilities : [(ownable: Ownable, category: LiabilitiesCategory)]) {
        //        autoreleasepool {
        self.year = year

        // initialiser les dictionnaires
        self.assets      = [AppSettings.shared.allPersonsLabel: ValuedAssets(name: "ACTIF")]
        self.liabilities = [AppSettings.shared.allPersonsLabel: ValuedLiabilities(name : "PASSIF")]
        membersName.forEach { name in
            self.assets[name]      = ValuedAssets(name : "ACTIF")
            self.liabilities[name] = ValuedLiabilities(name : "PASSIF")
        }

        // actifs
        for asset in assets {
            appendToAssets(asset.category, membersName, asset.ownable, year)
        }

        // dettes
        for liability in liabilities {
            appendToLiabilities(liability.category, membersName, liability.ownable, year)
        }
        //        }
    }

    // MARK: - Methods

    fileprivate mutating func appendToAssets(_ category       : AssetsCategory,
                                             _ membersName    : [String],
                                             _ asset          : Ownable,
                                             _ year           : Int) {
        let namePrefix: String
        switch category {

            case .sci:
                namePrefix = "SCI - "

            default:
                namePrefix = ""
        }

        assets[AppSettings.shared.allPersonsLabel]!.perCategory[category]?.namedValues
            .append((name  : namePrefix + asset.name,
                     value : asset.value(atEndOf: year).rounded()))

        membersName.forEach { name in
            let selected = isSelected(ownable  : asset, name  : name)
            let value    = graphicValueOf(ownable : asset, isSelected : selected, name : name)

            assets[name]!.perCategory[category]?.namedValues
                .append((name  : namePrefix + asset.name,
                         value : value))
        }
    }

    fileprivate mutating func appendToLiabilities(_ category       : LiabilitiesCategory,
                                                  _ membersName    : [String],
                                                  _ liability      : Ownable,
                                                  _ year           : Int) {
        liabilities[AppSettings.shared.allPersonsLabel]!.perCategory[category]?.namedValues
            .append((name  : liability.name,
                     value : liability.value(atEndOf: year).rounded()))

        membersName.forEach { name in
            let selected = isSelected(ownable: liability, name: name)
            let value    = graphicValueOf(ownable : liability, isSelected : selected, name : name)

            liabilities[name]!.perCategory[category]?.namedValues
                .append( (name  : liability.name,
                          value : value))
        }
    }

    fileprivate func isSelected(ownable: Ownable, name: String) -> Bool {
        switch UserSettings.shared.ownershipSelection {

            case .generatesRevenue:
                return ownable.providesRevenue(to: [name])

            case .sellable:
                return ownable.hasAFullOwner(in: [name])

            case .all:
                return ownable.isPartOfPatrimoine(of: [name])
        }
    }

    fileprivate func graphicValueOf(ownable: Ownable, isSelected: Bool, name: String) -> Double {
        guard isSelected else {
            return 0
        }
        switch UserSettings.shared.assetEvaluationMethod {
            
            case .totalValue:
                return ownable.value(atEndOf: year).rounded()
                
            case .ownedValue:
                return ownable.ownedValue(by              : name,
                                          atEndOf         : year,
                                          evaluationMethod: .patrimoine).rounded()
        }
    }
}

// MARK: - BalanceSheetLine extensions for VISITORS

extension BalanceSheetLine: BalanceSheetCsvVisitableP {
    func accept(_ visitor: BalanceSheetCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetLineChartVisitableP {
    func accept(_ visitor: BalanceSheetLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetCategoryStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
