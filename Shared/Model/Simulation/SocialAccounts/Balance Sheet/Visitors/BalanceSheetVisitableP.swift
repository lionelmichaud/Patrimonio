//
//  VisitorProtocol.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 09/05/2021.
//

import Foundation

/// The Component interface declares an `accept` method that should take the
/// base visitor interface as an argument.
protocol BalanceSheetCsvVisitableP {
    func accept(_ visitor: BalanceSheetCsvVisitorP)
}

protocol BalanceSheetLineChartVisitableP {
    func accept(_ visitor: BalanceSheetLineChartVisitorP)
}

protocol BalanceSheetStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetStackedBarChartVisitorP)
}

protocol BalanceSheetCategoryStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP)
}
