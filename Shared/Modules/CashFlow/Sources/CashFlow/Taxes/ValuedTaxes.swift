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

public struct ValuedTaxes: DictionaryOfNamedValueTableP {
    
    // MARK: - Properties
    
    public var name        : String                          = ""
    public var perCategory : [TaxeCategory: NamedValueTable] = [:]
    public var irpp        : IncomeTaxesModel.IRPP
    public var isf         : IsfModel.ISF

    public init() {
        self.irpp = (amount         : 0,
                     familyQuotient : 0,
                     marginalRate   : 0,
                     averageRate    : 0)
        self.isf = (amount       : 0,
                    taxable      : 0,
                    marginalRate : 0)
    }
}

extension ValuedTaxes: CustomStringConvertible {
    public var description: String {
        let nameStr = "Nom: \(name)\n"
        var tableStr = ""
        perCategory.forEach { category, revenues in
            tableStr += "\(category.displayString) :\n"
            tableStr += "\(String(describing: revenues).withPrefixedSplittedLines("  ")) :\n"
        }
        return nameStr + tableStr
    }
}

// MARK: - Extensions for VISITORS

extension ValuedTaxes: CashFlowCsvVisitableP {
    public func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension ValuedTaxes: CashFlowStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension ValuedTaxes: CashFlowCategoryStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}

extension ValuedTaxes: CashFlowIsfVisitableP {
    public func accept(_ visitor: CashFlowIsfVisitorP) {
        visitor.buildIsfChart(element: self)
    }
}

extension ValuedTaxes: CashFlowIrppRateVisitableP {
    public func accept(_ visitor: CashFlowIrppRateVisitorP) {
        visitor.buildIrppRateChart(element: self)
    }
}

extension ValuedTaxes: CashFlowIrppVisitableP {
    public func accept(_ visitor: CashFlowIrppVisitorP) {
        visitor.buildIrppChart(element: self)
    }
}
