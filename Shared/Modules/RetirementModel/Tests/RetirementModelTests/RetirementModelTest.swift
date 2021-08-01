//
//  RetirementModelTest.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import RetirementModel

class RetirementModelTest: XCTestCase {
    
    static var retirement: Retirement!

    // MARK: Helpers

    override class func setUp() {
        super.setUp()
        RetirementModelTest.retirement = Retirement(fromBundle : Bundle.module)
        Retirement.setSimulationMode(to: .deterministic)
    }

    // MARK: Tests

    func test_loading_from_module_bundle() {
        XCTAssertNoThrow(Retirement(fromBundle : Bundle.module),
                         "Failed to read HumanLife from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }

    func test_saving_to_module_bundle() {
        XCTAssertNoThrow(RetirementModelTest.retirement.saveAsJSON(toBundle: Bundle.module))
    }

    func test_ageMinimumLegal() {
        XCTAssertEqual(RetirementModelTest.retirement.ageMinimumLegal, 62)

        var retirement = Retirement(fromBundle : Bundle.module)
        retirement.ageMinimumLegal = 60
        XCTAssertEqual(retirement.ageMinimumLegal, 60)
        XCTAssertEqual(retirement.persistenceSM.currentState , .modified)
    }

    func test_ageMinimumAGIRC() {
        XCTAssertEqual(RetirementModelTest.retirement.ageMinimumAGIRC, 57)

        var retirement = Retirement(fromBundle : Bundle.module)
        retirement.ageMinimumAGIRC = 50
        XCTAssertEqual(retirement.ageMinimumAGIRC, 50)
        XCTAssertEqual(retirement.persistenceSM.currentState , .modified)
    }

    func test_valeurDuPointAGIRC() {
        XCTAssertEqual(RetirementModelTest.retirement.valeurDuPointAGIRC, 1.2714)

        var retirement = Retirement(fromBundle : Bundle.module)
        retirement.valeurDuPointAGIRC = 2.54
        XCTAssertEqual(retirement.valeurDuPointAGIRC, 2.54)
        XCTAssertEqual(retirement.persistenceSM.currentState , .modified)
    }

}
