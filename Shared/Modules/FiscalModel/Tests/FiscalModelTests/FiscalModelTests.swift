//
//  FiscalModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import FiscalModel
import AppFoundation

class FiscalModelTests: XCTestCase {

    func test_loading_from_module_bundle() {
        XCTAssertNoThrow(Fiscal.Model(fromBundle: Bundle.module).initialized(),
                         "Failed to read model from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }
    
    func test_saving_to_test_bundle() throws {
        let model = Fiscal.Model(fromBundle: Bundle.module).initialized()
        model.saveToBundle(toBundle             : Bundle.module,
                           dateEncodingStrategy : .iso8601,
                           keyEncodingStrategy  : .useDefaultKeys)
    }

}
