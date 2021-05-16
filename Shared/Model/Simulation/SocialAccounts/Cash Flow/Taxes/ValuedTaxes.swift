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

extension ValuedTaxes: CashFlowCsvVisitableP {
    func accept(_ visitor: CashFlowCsvVisitorP) {
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

extension ValuedTaxes: CashFlowIsfVisitableP {
    func accept(_ visitor: CashFlowIsfVisitorP) {
        visitor.buildIsfChart(element: self)
    }
}

extension ValuedTaxes: CashFlowIrppRateVisitableP {
    func accept(_ visitor: CashFlowIrppRateVisitorP) {
        visitor.buildIrppRateChart(element: self)
    }
}

extension ValuedTaxes: CashFlowIrppVisitableP {
    func accept(_ visitor: CashFlowIrppVisitorP) {
        visitor.buildIrppChart(element: self)
    }
}
