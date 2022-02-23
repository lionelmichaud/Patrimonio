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

    func test_state_machine() {
        let humanLife = HumanLife(fromBundle : Bundle.module)
        
        XCTAssertFalse(humanLife.isModified)
        
        humanLife.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(humanLife.isModified)
    }
}
