//
//  PensionReversionTest.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import RetirementModel

class PensionReversionTest: XCTestCase {
    typealias Tests = PensionReversionTest
    
    static var reversion: PensionReversion!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = PensionReversion.Model(fromFile   : "PensionReversionModel.json",
                                           fromBundle : Bundle.module)
        Tests.reversion = PensionReversion(model: model)
    }
    
    // MARK: Tests
    
    func test_loading_model_from_module_bundle() {
        XCTAssertNoThrow(PensionReversion.Model(fromFile   : "PensionReversionModel.json",
                                                fromBundle : Bundle.module),
                         "Failed to read PensionReversion.Model from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }
    
    func test_saving_model_to_test_bundle() throws {
        XCTAssertNoThrow(Tests.reversion.saveAsJSON(toFile               : "PensionReversionModel.json",
                                                                   toBundle             : Bundle.module,
                                                                   dateEncodingStrategy : .iso8601,
                                                                   keyEncodingStrategy  : .useDefaultKeys))
    }
    
    func test_pension_new_reversion() {
        let pensionDecedent = 2000.0
        let pensionSpouse   = 1000.0
        
        let reversion = Tests
            .reversion.nouvellePensionReversion(pensionDecedent: pensionDecedent,
                                                pensionSpouse  : pensionSpouse)
        
        XCTAssertEqual((pensionDecedent + pensionSpouse) * 0.7, reversion)
    }
    
    func test_anciennePensionReversionGeneral() {
        var reversion = Tests
            .reversion.anciennePensionReversionGeneral(bornChildrenNumber: 0)
        XCTAssertEqual(Tests.reversion.model.oldModel.general.minimum, reversion)

        reversion = Tests
            .reversion.anciennePensionReversionGeneral(bornChildrenNumber: 3)
        XCTAssertEqual(reversion,
                       Tests.reversion.model.oldModel.general.minimum *
                        (1.0 + Tests.reversion.model.oldModel.general.majoration3enfants/100.0))
    }
    
    func test_anciennePensionReversionAgircArcco() {
        var reversion = Tests
            .reversion.anciennePensionReversionAgircArcco(pensionCompDecedent : 100.0,
                                                          spouseAge           : 54)
        XCTAssertEqual(reversion, 0)
        
        reversion = Tests
            .reversion.anciennePensionReversionAgircArcco(pensionCompDecedent : 100.0,
                                                          spouseAge           : 55)
        XCTAssertEqual(reversion,
                       100.0 * Tests.reversion.model.oldModel.agircArcco.fractionConjoint / 100.0)
    }
    
    func test_anciennePensionReversion() {
        let reversion = Tests
            .reversion.anciennePensionReversion(pensionSpouse       : 1000.0,
                                                pensionCompDecedent : 100.0,
                                                spouseAge           : 55,
                                                bornChildrenNumber  : 3)
        XCTAssertEqual(reversion,
                       1000.0 +
                        Tests.reversion.model.oldModel.general.minimum *
                        (1.0 + Tests.reversion.model.oldModel.general.majoration3enfants/100.0) +
                        100.0 * Tests.reversion.model.oldModel.agircArcco.fractionConjoint / 100.0)
    }
    
    func test_pensionReversion() {
        let reversion = Tests
            .reversion.pensionReversion(pensionDecedent     : 1500.0,
                                        pensionSpouse       : 1000.0,
                                        pensionCompDecedent : 100.0,
                                        spouseAge           : 55,
                                        bornChildrenNumber  : 3)
        XCTAssertEqual(reversion,
                       1000.0 +
                        Tests.reversion.model.oldModel.general.minimum *
                        (1.0 + Tests.reversion.model.oldModel.general.majoration3enfants/100.0) +
                        100.0 * Tests.reversion.model.oldModel.agircArcco.fractionConjoint / 100.0)

    }
}
