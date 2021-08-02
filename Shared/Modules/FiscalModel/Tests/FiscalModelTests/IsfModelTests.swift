//
//  IsfTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import FiscalModel

class IsfModelTests: XCTestCase {
    
    static var isfTaxes: IsfModel!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = IsfModel.Model(
            fromFile   : IsfModel.Model.defaultFileName,
            fromBundle : Bundle.module)
        IsfModelTests.isfTaxes = IsfModel(model: model)
        do {
            try IsfModelTests.isfTaxes.initialize()
        } catch {
            XCTFail("Failed to initialize the model")
        }
    }
    
    // MARK: Tests
    
    func test_isf() throws {
        // inférieur au seuil de taxation
        var isf: IsfModel.ISF
        
        isf = try IsfModelTests.isfTaxes.isf(taxableAsset: 1_000_000)
        XCTAssertEqual(0.0, isf.amount)
        XCTAssertEqual(1_000_000.0, isf.taxable)
        XCTAssertEqual(0.0, isf.marginalRate)

        // supérieur au seuil de taxation / dans la zone intermédiaire
        isf = try IsfModelTests.isfTaxes.isf(taxableAsset: 1_350_000)
        XCTAssertEqual(2_225.0, isf.amount)
        XCTAssertEqual(1_350_000.0, isf.taxable)
        XCTAssertEqual(0.007, isf.marginalRate)

        // supérieur au seuil de taxation / au-delà de la zone intermédiaire
        isf = try IsfModelTests.isfTaxes.isf(taxableAsset: 2_000_000)
        XCTAssertEqual(7_400.0, isf.amount)
        XCTAssertEqual(2_000_000.0, isf.taxable)
        XCTAssertEqual(0.007, isf.marginalRate)
        
        // supérieur au seuil de taxation / au-delà de la zone intermédiaire
        isf = try IsfModelTests.isfTaxes.isf(taxableAsset: 3_000_000)
        XCTAssertEqual(15_690.0, isf.amount)
        XCTAssertEqual(3_000_000.0, isf.taxable)
        XCTAssertEqual(0.01, isf.marginalRate)
    }
}
