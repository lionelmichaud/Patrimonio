//
//  HumanLifeTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import HumanLifeModel

class HumanLifeTests: XCTestCase {
    
    static var humanLife: HumanLife!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        HumanLifeTests.humanLife = HumanLife(fromBundle : Bundle.module)
    }
    
    // MARK: Tests

    func test_loading_from_module_bundle() {
        XCTAssertNoThrow(HumanLife(fromBundle : Bundle.module),
                         "Failed to read HumanLife from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }

    func test_saving_to_module_bundle() {
        XCTAssertNoThrow(HumanLifeTests.humanLife.saveAsJSON(toBundle: Bundle.module))
    }

    func test_get_set_menLifeExpectationDeterministic() {
        XCTAssertEqual(HumanLifeTests.humanLife.menLifeExpectationDeterministic, 82)

        var humanLife = HumanLife(fromBundle : Bundle.module)
        humanLife.menLifeExpectationDeterministic = 60
        XCTAssertEqual(humanLife.menLifeExpectationDeterministic, 60)
        XCTAssertEqual(humanLife.persistenceSM.currentState , .modified)
    }

    func test_get_set_womenLifeExpectationDeterministic() {
        XCTAssertEqual(HumanLifeTests.humanLife.womenLifeExpectationDeterministic, 89)

        var humanLife = HumanLife(fromBundle : Bundle.module)
        humanLife.womenLifeExpectationDeterministic = 50
        XCTAssertEqual(humanLife.womenLifeExpectationDeterministic, 50)
        XCTAssertEqual(humanLife.persistenceSM.currentState , .modified)
    }

    func test_get_set_nbOfYearsOfdependencyDeterministic() {
        XCTAssertEqual(HumanLifeTests.humanLife.nbOfYearsOfdependencyDeterministic, 6)

        var humanLife = HumanLife(fromBundle : Bundle.module)
        humanLife.nbOfYearsOfdependencyDeterministic = 4
        XCTAssertEqual(humanLife.nbOfYearsOfdependencyDeterministic, 4)
        XCTAssertEqual(humanLife.persistenceSM.currentState , .modified)
    }

    func test_state_machine() {
        var humanLife = HumanLife(fromBundle : Bundle.module)
        
        XCTAssertFalse(humanLife.isModified)
        
        humanLife.menLifeExpectationDeterministic = 2
        XCTAssertTrue(humanLife.isModified)
        humanLife.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(humanLife.isModified)
        
        humanLife.womenLifeExpectationDeterministic = 2
        XCTAssertTrue(humanLife.isModified)
        humanLife.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(humanLife.isModified)
        
        humanLife.nbOfYearsOfdependencyDeterministic = 2
        XCTAssertTrue(humanLife.isModified)
        humanLife.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(humanLife.isModified)
    }
}
