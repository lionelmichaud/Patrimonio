//
//  ValuedAssets.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue

// MARK: - agrégat des Actifs

struct ValuedAssets: DictionaryOfNamedValueTable {
    
    // MARK: - Properties
    
    var name       : String = ""
    var perCategory: [AssetsCategory: NamedValueTable] = [:]

    init() { }
}

// MARK: - Extensions for VISITORS

extension ValuedAssets: BalanceSheetVisitableP {
    func accept(_ visitor: BalanceSheetVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension ValuedAssets: BalanceSheetLineChartVisitableP {
    func accept(_ visitor: BalanceSheetLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension ValuedAssets: BalanceSheetStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension ValuedAssets: BalanceSheetCategoryStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
