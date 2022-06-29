//
//  FinancialRevenuTaxesModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import FiscalModel
import Numerics

class FinancialRevenuTaxesModelTests: XCTestCase {
    
    static var financialRevenuTaxes: FinancialRevenuTaxesModel!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = FinancialRevenuTaxesModel.Model(
            fromFile   : FinancialRevenuTaxesModel.Model.defaultFileName,
            fromBundle : Bundle.module)
        FinancialRevenuTaxesModelTests.financialRevenuTaxes = FinancialRevenuTaxesModel(model: model)
    }
    
    // MARK: Tests
    
    func test_calcul_charges_totales() {
        XCTAssertEqual(0.5 + 9.5 + 7.5,
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.model.totalSocialTaxes)
        XCTAssert(FinancialRevenuTaxesModelTests.financialRevenuTaxes.model.totalSocialTaxes.isApproximatelyEqual(to: 0.5 + 9.5 + 7.5,
                                                                                                    absoluteTolerance: 0.0001))
    }
    
    func test_calcul_net() {
        XCTAssertEqual(100.0 - (0.5 + 9.5 + 7.5),
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.netOfSocialTaxes(100.0))
        XCTAssertEqual(-100.0,
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.netOfSocialTaxes(-100.0))
    }
    
    func test_calcul_brut() {
        XCTAssertEqual(100.0,
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.brutOfSocialTaxes(100.0 - (0.5 + 9.5 + 7.5)))
        XCTAssertEqual(-100.0,
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.brutOfSocialTaxes(-100.0))
    }
    
    func test_calcul_social_taxes() {
        XCTAssertEqual((0.5 + 9.5 + 7.5),
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.socialTaxes(100.0))
        XCTAssertEqual(0.0,
                       FinancialRevenuTaxesModelTests.financialRevenuTaxes.socialTaxes(-100.0))
    }
}
