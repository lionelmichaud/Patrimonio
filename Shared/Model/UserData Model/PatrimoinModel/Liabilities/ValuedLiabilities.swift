//
//  ValuedLiabilities.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue

// MARK: - agrégat des Passifs

struct ValuedLiabilities: DictionaryOfNamedValueTableP {
    
    // MARK: - Properties
    
    var name       : String = ""
    var perCategory: [LiabilitiesCategory: NamedValueTable] = [:]
    
    init() { }
}

// MARK: - Extensions for VISITORS

extension ValuedLiabilities: BalanceSheetCsvVisitableP {
    func accept(_ visitor: BalanceSheetCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension ValuedLiabilities: BalanceSheetLineChartVisitableP {
    func accept(_ visitor: BalanceSheetLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension ValuedLiabilities: BalanceSheetStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension ValuedLiabilities: BalanceSheetCategoryStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
