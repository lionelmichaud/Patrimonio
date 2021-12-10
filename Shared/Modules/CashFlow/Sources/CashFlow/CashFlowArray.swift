//
//  CashFlowArray.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue

// MARK: - CashFlowArray: Table des cash flow annuels

public typealias CashFlowArray = [CashFlowLine]

// MARK: - CashFlowArray extension for CSV export

public extension CashFlowArray {
    /// Rend la ligne de Cash Flow pour une année donnée
    /// - Parameter year: l'année recherchée
    /// - Returns: le cash flow de l'année
    subscript(year: Int) -> CashFlowLine? {
        self.first { line in
            line.year == year
        }
    }
    
    /// Construction de la légende du graphique
    /// - Parameter combination: sélection de la catégories de séries à afficher
    /// - Returns: tableau des libéllés des sries des catégories sélectionnées
    func getCashFlowLegend(_ combination: CashCombination = .both) -> ItemSelectionList {
        let firstLine   = self.first!
        switch combination {
            case .revenues:
                // libellés des revenus famille + revenus SCI
                let revenuesLegend =
                    firstLine
                    .adultsRevenues
                    .summary
                    .namedValues
                    .map({(label    : $0.name,
                           selected : true)})
                // Résumé seulement
                let sciLegend =
                    firstLine
                    .sciCashFlowLine
                    .summary
                    .namedValues
                    .map {(label    : $0.name,
                           selected : true)}
                return revenuesLegend + sciLegend
                
            case .expenses:
                // à plat
                let taxesLegend =
                    firstLine
                    .adultTaxes
                    .summary
                    .namedValues
                    .map {(label: $0.name,
                           selected: true)}
                // Résumé seulement
                let expenseLegend = (label    : firstLine.lifeExpenses.tableName,
                                     selected : true)
                // Résumé seulement
                let debtsLegend = (label    : firstLine.debtPayements.tableName,
                                   selected : true)
                // Résumé seulement
                let investsLegend = (label    : firstLine.investPayements.tableName,
                                     selected : true)
                return [expenseLegend] + taxesLegend + [debtsLegend, investsLegend]
                
            case .both:
                return getCashFlowLegend(.revenues) + getCashFlowLegend(.expenses)
        }
    }
}

// MARK: - Extensions for VISITORS

extension CashFlowArray: CashFlowCsvVisitableP {
    public func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension CashFlowArray: CashFlowLineChartVisitableP {
    public func accept(_ visitor: CashFlowLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension CashFlowArray: CashFlowStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension CashFlowArray: CashFlowIrppVisitableP {
    public func accept(_ visitor: CashFlowIrppVisitorP) {
        visitor.buildIrppChart(element: self)
    }
}

extension CashFlowArray: CashFlowIrppRateVisitableP {
    public func accept(_ visitor: CashFlowIrppRateVisitorP) {
        visitor.buildIrppRateChart(element: self)
    }
}

extension CashFlowArray: CashFlowIrppSliceVisitableP {
    public func accept(_ visitor: CashFlowIrppSliceVisitorP) {
        visitor.buildIrppSliceChart(element: self)
    }
}

extension CashFlowArray: CashFlowIsfVisitableP {
    public func accept(_ visitor: CashFlowIsfVisitorP) {
        visitor.buildIsfChart(element: self)
    }
}