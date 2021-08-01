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

    // MARK: Helpers

    // MARK: Tests

    func test_loading_from_module_bundle() throws {
        XCTAssertNoThrow(SocioEconomy.Model(fromFile   : "SocioEconomyModelConfig.json",
                                            fromBundle : Bundle.module).initialized(),
                         "Failed to read model from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }
    
    func test_saving_to_module_bundle() throws {
        let model = SocioEconomy.Model(fromFile   : "SocioEconomyModelConfig.json",
                                       fromBundle : Bundle.module).initialized()
        model.saveAsJSON(toFile               : "SocioEconomyModelConfig.json",
                         toBundle             : Bundle.module,
                         dateEncodingStrategy : .iso8601,
                         keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func test_next_currentRandomizersValues_setRandomValue() {
        var model = SocioEconomy.Model(fromFile   : "SocioEconomyModelConfig.json",
                                       fromBundle : Bundle.module).initialized()
        var dico = model.nextRun()
        
        XCTAssertNotNil(dico[.expensesUnderEvaluationRate])
        XCTAssertNotNil(dico[.nbTrimTauxPlein])
        XCTAssertNotNil(dico[.pensionDevaluationRate])

        var currentRandomizersValues = model.currentRandomizersValues(withMode: .random)
        XCTAssertNotNil(currentRandomizersValues[.expensesUnderEvaluationRate])
        XCTAssertNotNil(currentRandomizersValues[.nbTrimTauxPlein])
        XCTAssertNotNil(currentRandomizersValues[.pensionDevaluationRate])

        XCTAssertEqual(dico, currentRandomizersValues)

        for (v, value) in dico {
            dico[v] = value + 1.0
        }
        model.setRandomValue(to: dico)

        currentRandomizersValues = model.currentRandomizersValues(withMode: .random)
        XCTAssertNotNil(currentRandomizersValues[.expensesUnderEvaluationRate])
        XCTAssertNotNil(currentRandomizersValues[.nbTrimTauxPlein])
        XCTAssertNotNil(currentRandomizersValues[.pensionDevaluationRate])

        XCTAssertEqual(dico, currentRandomizersValues)
    }

    func test_pensionDevaluationRate() {
        let model = SocioEconomy.Model(fromFile   : "SocioEconomyModelConfig.json",
                                       fromBundle : Bundle.module).initialized()
        XCTAssertEqual(model.pensionDevaluationRate(withMode: .deterministic),
                       1.0)
    }

    func test_nbTrimTauxPlein() {
        let model = SocioEconomy.Model(fromFile   : "SocioEconomyModelConfig.json",
                                       fromBundle : Bundle.module).initialized()
        XCTAssertEqual(model.nbTrimTauxPlein(withMode: .deterministic),
                       0)
    }

    func test_expensesUnderEvaluationRate() {
        let model = SocioEconomy.Model(fromFile   : "SocioEconomyModelConfig.json",
                                       fromBundle : Bundle.module).initialized()
        XCTAssertEqual(model.expensesUnderEvaluationRate(withMode: .deterministic),
                       5)
    }

}
