//
//  File.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/05/2021.
//

import Foundation

/// The Component interface declares an `accept` method that should take the
/// base visitor interface as an argument.
protocol CashFlowVisitableP {
    func accept(_ visitor: CashFlowVisitorP)
}

protocol CashFlowLineChartVisitableP {
    func accept(_ visitor: CashFlowLineChartVisitorP)
}

protocol CashFlowStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowStackedBarChartVisitorP)
}

protocol CashFlowCategoryStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP)
}
