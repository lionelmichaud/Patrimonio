//
//  ValuedLiabilities.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue
import Liabilities

// MARK: - agrégat des Passifs

public struct ValuedLiabilities: DictionaryOfNamedValueTableP {
    
    // MARK: - Properties
    
    public var name       : String = ""
    public var perCategory: [LiabilitiesCategory: NamedValueTable] = [:]
    
    public init() { }
}

// MARK: - Extensions for VISITORS

extension ValuedLiabilities: BalanceSheetCsvVisitableP {
    public func accept(_ visitor: BalanceSheetCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension ValuedLiabilities: BalanceSheetLineChartVisitableP {
    public func accept(_ visitor: BalanceSheetLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension ValuedLiabilities: BalanceSheetStackedBarChartVisitableP {
    public func accept(_ visitor: BalanceSheetStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension ValuedLiabilities: BalanceSheetCategoryStackedBarChartVisitableP {
    public func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
