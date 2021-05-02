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

    func test_loading_from_main_bundle() throws {
        XCTAssertNoThrow(Unemployment.Model(fromBundle: Bundle.module), "Failed to read model from Main Bundle ")
    }
    
    func test_saving_to_test_bundle() throws {
        let model = Unemployment.Model()
        model.saveToBundle(toBundle             : Bundle.module,
                           dateEncodingStrategy: .iso8601,
                           keyEncodingStrategy: .useDefaultKeys)
    }
    
}
