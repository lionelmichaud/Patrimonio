//
//  CsvVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/05/2021.
//

import Foundation

/// The Visitor Interface declares a set of visiting methods that correspond to
/// component classes. The signature of a visiting method allows the visitor to
/// identify the exact class of the component that it's dealing with.
protocol BalanceSheetCsvVisitorP {
    // Elements de Bilan
    func buildCsv(element: BalanceSheetArray)
    func buildCsv(element: BalanceSheetLine)
    func buildCsv(element: ValuedAssets)
    func buildCsv(element: ValuedLiabilities)
}

protocol BalanceSheetLineChartVisitorP {
    // Elements de Bilan
    func buildLineChart(element: BalanceSheetArray)
    func buildLineChart(element: BalanceSheetLine)
    func buildLineChart(element: ValuedAssets)
    func buildLineChart(element: ValuedLiabilities)
}

protocol BalanceSheetStackedBarChartVisitorP {
    // Elements de Bilan
    func buildStackedBarChart(element: BalanceSheetArray)
    func buildStackedBarChart(element: BalanceSheetLine)
    func buildStackedBarChart(element: ValuedAssets)
    func buildStackedBarChart(element: ValuedLiabilities)
}

protocol BalanceSheetCategoryStackedBarChartVisitorP {
    // Elements de Bilan
    func buildCategoryStackedBarChart(element: BalanceSheetArray)
    func buildCategoryStackedBarChart(element: BalanceSheetLine)
    func buildCategoryStackedBarChart(element: ValuedAssets)
    func buildCategoryStackedBarChart(element: ValuedLiabilities)

}
