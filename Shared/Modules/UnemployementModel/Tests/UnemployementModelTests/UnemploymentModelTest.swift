//
//  UnemploymentModelTest.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import UnemployementModel

class UnemploymentModelTest: XCTestCase {

    static var unemployment: Unemployment!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        UnemploymentModelTest.unemployment = Unemployment(fromBundle : Bundle.module)
    }
    
    // MARK: Tests
    
    func test_loading_from_module_bundle() throws {
        XCTAssertNoThrow(Unemployment(fromBundle : Bundle.module),
                         "Failed to read HumanLife from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }
    
    func test_saving_to_module_bundle() throws {
        XCTAssertNoThrow(UnemploymentModelTest.unemployment.saveAsJSON(toBundle: Bundle.module))
    }
    
}
