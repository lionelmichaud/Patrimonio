//
//  CashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/05/2021.
//

import Foundation

/// The Visitor Interface declares a set of visiting methods that correspond to
/// component classes. The signature of a visiting method allows the visitor to
/// identify the exact class of the component that it's dealing with.
protocol CashFlowVisitorP {
    // Elements de CASH FLOW
    func buildCsv(element: CashFlowArray)
    func buildCsv(element: CashFlowLine)
    func buildCsv(element: ValuedRevenues)
    func buildCsv(element: ValuedTaxes)
    func buildCsv(element: SciCashFlowLine)
    func buildCsv(element: SciCashFlowLine.Revenues)
}

protocol CashFlowLineChartVisitorP {
    // Elements de Bilan
    func buildLineChart(element: CashFlowArray)
    func buildLineChart(element: CashFlowLine)
}

protocol CashFlowStackedBarChartVisitorP {
    // Elements de Bilan
    func buildStackedBarChart(element: CashFlowArray)
    func buildStackedBarChart(element: CashFlowLine)
    func buildStackedBarChart(element: ValuedTaxes)
    func buildStackedBarChart(element: ValuedRevenues)
    func buildStackedBarChart(element: SciCashFlowLine)
}

protocol CashFlowCategoryStackedBarChartVisitorP {
    // Elements de Bilan
    func buildCategoryStackedBarChart(element: CashFlowArray)
    func buildCategoryStackedBarChart(element: CashFlowLine)
    func buildCategoryStackedBarChart(element: ValuedTaxes)
    func buildCategoryStackedBarChart(element: ValuedRevenues)
    func buildCategoryStackedBarChart(element: SciCashFlowLine)
    func buildCategoryStackedBarChart(element: SciCashFlowLine.Revenues)
}
