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

    static var fiscal: Fiscal!
    
    // MARK: Helpers
    
    override func setUpWithError() throws { // 2.
        // This is the setUpWithError() instance method.
        // It is called before each test method begins.
        // Set up any per-test state here.
        XCTAssertNoThrow(FiscalModelTests.fiscal = Fiscal(fromBundle : Bundle.module),
                         "Failed to read model from Module Bundle \(String(describing: Bundle.module.resourcePath))")
    }
    
    // MARK: Tests
    
    func test_saving_to_module_bundle() throws {
        FiscalModelTests.fiscal.saveAsJSON(toBundle: Bundle.module)
    }
    
    func test_saving_to_test_bundle() throws {
        let model =
            Fiscal.Model(fromFile: Fiscal.Model.defaultFileName, fromBundle: Bundle.module)
            .initialized()
        model.saveAsJSON(toFile               : Fiscal.Model.defaultFileName,
                         toBundle             : Bundle.module,
                         dateEncodingStrategy : .iso8601,
                         keyEncodingStrategy  : .useDefaultKeys)
    }

    func test_state_machine() {
        XCTAssertFalse(FiscalModelTests.fiscal.isModified)
        
        FiscalModelTests.fiscal.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(FiscalModelTests.fiscal.isModified)
    }
}
