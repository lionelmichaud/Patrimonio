//
//  ValuedAssets.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue
import AssetsModel

// MARK: - agrégat des Actifs

public struct ValuedAssets: DictionaryOfNamedValueTableP {
    
    // MARK: - Properties
    
    public var name       : String = ""
    public var perCategory: [AssetsCategory: NamedValueTable] = [:]

    public init() { }
}

// MARK: - Extensions for VISITORS

extension ValuedAssets: BalanceSheetCsvVisitableP {
    public func accept(_ visitor: BalanceSheetCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension ValuedAssets: BalanceSheetLineChartVisitableP {
    public func accept(_ visitor: BalanceSheetLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension ValuedAssets: BalanceSheetStackedBarChartVisitableP {
    public func accept(_ visitor: BalanceSheetStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension ValuedAssets: BalanceSheetCategoryStackedBarChartVisitableP {
    public func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
