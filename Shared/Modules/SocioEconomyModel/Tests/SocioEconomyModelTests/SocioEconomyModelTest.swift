//
//  SocioEconomyModelTest.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import SocioEconomyModel

class SocioEconomyModelTest: XCTestCase {

    func test_loading_from_main_bundle() throws {
        XCTAssertNoThrow(SocioEconomy.Model(fromBundle: Bundle.module).initialized(), "Failed to read model from Main Bundle ")
    }
    
    func test_saving_to_test_bundle() throws {
        let model = SocioEconomy.Model(fromBundle: Bundle.module).initialized()
        model.saveToBundle(toBundle             : Bundle.module,
                           dateEncodingStrategy : .iso8601,
                           keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func test_next() {
        var model = SocioEconomy.Model(fromBundle: Bundle.module).initialized()
        let dico = model.next()
        
        XCTAssertNotNil(dico[.expensesUnderEvaluationRate])
        XCTAssertNotNil(dico[.nbTrimTauxPlein])
        XCTAssertNotNil(dico[.pensionDevaluationRate])
    }
}
