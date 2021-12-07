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
public protocol CashFlowCsvVisitorP {
    // Elements de CASH FLOW
    func buildCsv(element: CashFlowArray)
    func buildCsv(element: CashFlowLine)
    func buildCsv(element: ValuedRevenues)
    func buildCsv(element: ValuedTaxes)
    func buildCsv(element: SciCashFlowLine)
    func buildCsv(element: SciCashFlowLine.Revenues)
}

public protocol CashFlowLineChartVisitorP {
    // Elements de Bilan
    func buildLineChart(element: CashFlowArray)
    func buildLineChart(element: CashFlowLine)
}

public protocol CashFlowStackedBarChartVisitorP {
    // Elements de Bilan
    func buildStackedBarChart(element: CashFlowArray)
    func buildStackedBarChart(element: CashFlowLine)
    func buildStackedBarChart(element: ValuedTaxes)
    func buildStackedBarChart(element: ValuedRevenues)
    func buildStackedBarChart(element: SciCashFlowLine)
}

public protocol CashFlowCategoryStackedBarChartVisitorP {
    // Elements de Bilan
    func buildCategoryStackedBarChart(element: CashFlowArray)
    func buildCategoryStackedBarChart(element: CashFlowLine)
    func buildCategoryStackedBarChart(element: ValuedTaxes)
    func buildCategoryStackedBarChart(element: ValuedRevenues)
    func buildCategoryStackedBarChart(element: SciCashFlowLine)
}

public protocol CashFlowIrppVisitorP {
    // Elements de Bilan
    func buildIrppChart(element: CashFlowArray)
    func buildIrppChart(element: CashFlowLine)
    func buildIrppChart(element: ValuedTaxes)
}

public protocol CashFlowIrppRateVisitorP {
    // Elements de Bilan
    func buildIrppRateChart(element: CashFlowArray)
    func buildIrppRateChart(element: CashFlowLine)
    func buildIrppRateChart(element: ValuedTaxes)
}

public protocol CashFlowIrppSliceVisitorP {
    // Elements de Bilan
    func buildIrppSliceChart(element: CashFlowArray)
}

public protocol CashFlowIsfVisitorP {
    // Elements de Bilan
    func buildIsfChart(element: CashFlowArray)
    func buildIsfChart(element: CashFlowLine)
    func buildIsfChart(element: ValuedTaxes)
}
