//
//  File.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/05/2021.
//

import Foundation

/// The Component interface declares an `accept` method that should take the
/// base visitor interface as an argument.
protocol CashFlowCsvVisitableP {
    func accept(_ visitor: CashFlowCsvVisitorP)
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

protocol CashFlowIrppVisitableP {
    func accept(_ visitor: CashFlowIrppVisitorP)
}

protocol CashFlowIrppRateVisitableP {
    func accept(_ visitor: CashFlowIrppRateVisitorP)
}

protocol CashFlowIrppSliceVisitableP {
    func accept(_ visitor: CashFlowIrppSliceVisitorP)
}

protocol CashFlowIsfVisitableP {
    func accept(_ visitor: CashFlowIsfVisitorP)
}
