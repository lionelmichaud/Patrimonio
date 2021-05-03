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
    
    func test_loading_from_module_bundle() throws {
        XCTAssertNoThrow(Retirement.Model(fromBundle: Bundle.module).initialized(),
                         "Failed to read model from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }
    
    func test_saving_to_test_bundle() throws {
        let model = Retirement.Model(fromBundle: Bundle.module).initialized()
        model.saveToBundle(toBundle             : Bundle.module,
                           dateEncodingStrategy : .iso8601,
                           keyEncodingStrategy  : .useDefaultKeys)
    }
}
