//
//  Taxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/08/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import FiscalModel
import NamedValue

// MARK: - agrégat des Taxes

struct ValuedTaxes: DictionaryOfNamedValueTable {
    
    // MARK: - Properties
    
    var name        : String                          = ""
    var perCategory : [TaxeCategory: NamedValueTable] = [:]
    var irpp        : IncomeTaxesModel.IRPP
    var isf         : IsfModel.ISF

    init() {
        self.irpp = (amount         : 0,
                     familyQuotient : 0,
                     marginalRate   : 0,
                     averageRate    : 0)
        self.isf = (amount       : 0,
                    taxable      : 0,
                    marginalRate : 0)
    }
}

// MARK: - Extensions for VISITORS

extension ValuedTaxes: CashFlowVisitableP {
    func accept(_ visitor: CashFlowVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension ValuedTaxes: CashFlowStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension ValuedTaxes: CashFlowCategoryStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
