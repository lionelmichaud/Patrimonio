//
//  File.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/05/2021.
//

import Foundation

/// The Component interface declares an `accept` method that should take the
/// base visitor interface as an argument.
public protocol CashFlowCsvVisitableP {
    func accept(_ visitor: CashFlowCsvVisitorP)
}

public protocol CashFlowLineChartVisitableP {
    func accept(_ visitor: CashFlowLineChartVisitorP)
}

public protocol CashFlowStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowStackedBarChartVisitorP)
}

public protocol CashFlowCategoryStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP)
}

public protocol CashFlowIrppVisitableP {
    func accept(_ visitor: CashFlowIrppVisitorP)
}

public protocol CashFlowIrppRateVisitableP {
    func accept(_ visitor: CashFlowIrppRateVisitorP)
}

public protocol CashFlowIrppSliceVisitableP {
    func accept(_ visitor: CashFlowIrppSliceVisitorP)
}

public protocol CashFlowIsfVisitableP {
    func accept(_ visitor: CashFlowIsfVisitorP)
}
