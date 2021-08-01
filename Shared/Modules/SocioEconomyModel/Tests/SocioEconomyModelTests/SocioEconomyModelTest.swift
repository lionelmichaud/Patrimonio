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

    static var socioEconomy: SocioEconomy!

    // MARK: Helpers

    override func setUpWithError() throws {
        super.setUp()
        SocioEconomyModelTest.socioEconomy = SocioEconomy(fromBundle : Bundle.module)
    }
    
    // MARK: Tests

    func test_loading_from_module_bundle() throws {
        XCTAssertNoThrow(SocioEconomy(fromBundle : Bundle.module),
                         "Failed to read model from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }
    
    func test_saving_to_module_bundle() throws {
        XCTAssertNoThrow(SocioEconomyModelTest.socioEconomy.saveAsJSON(toBundle: Bundle.module))
    }
    
    func test_next_currentRandomizersValues_setRandomValue() {
        var dico = SocioEconomyModelTest.socioEconomy.model!.nextRun()
        
        XCTAssertNotNil(dico[.expensesUnderEvaluationRate])
        XCTAssertNotNil(dico[.nbTrimTauxPlein])
        XCTAssertNotNil(dico[.pensionDevaluationRate])
        
        var currentRandomizersValues =
            SocioEconomyModelTest.socioEconomy.model!
            .currentRandomizersValues(withMode: .random)
        XCTAssertNotNil(currentRandomizersValues[.expensesUnderEvaluationRate])
        XCTAssertNotNil(currentRandomizersValues[.nbTrimTauxPlein])
        XCTAssertNotNil(currentRandomizersValues[.pensionDevaluationRate])
        
        XCTAssertEqual(dico, currentRandomizersValues)
        
        for (v, value) in dico {
            dico[v] = value + 1.0
        }
        SocioEconomyModelTest.socioEconomy.model!.setRandomValue(to: dico)
        
        currentRandomizersValues =
            SocioEconomyModelTest.socioEconomy.model!
            .currentRandomizersValues(withMode: .random)
        XCTAssertNotNil(currentRandomizersValues[.expensesUnderEvaluationRate])
        XCTAssertNotNil(currentRandomizersValues[.nbTrimTauxPlein])
        XCTAssertNotNil(currentRandomizersValues[.pensionDevaluationRate])

        XCTAssertEqual(dico, currentRandomizersValues)
    }

    func test_pensionDevaluationRate() {
        XCTAssertEqual(SocioEconomyModelTest.socioEconomy.pensionDevaluationRateDeterministic,
                       1.0)

        var socioEconomy = SocioEconomy(fromBundle : Bundle.module)
        socioEconomy.pensionDevaluationRateDeterministic = 60
        XCTAssertEqual(socioEconomy.pensionDevaluationRateDeterministic, 60)
        XCTAssertEqual(socioEconomy.persistenceSM.currentState , .modified)
    }

    func test_nbTrimTauxPlein() {
        XCTAssertEqual(SocioEconomyModelTest.socioEconomy.nbTrimTauxPleinDeterministic,
                       0)

        var socioEconomy = SocioEconomy(fromBundle : Bundle.module)
        socioEconomy.nbTrimTauxPleinDeterministic = 50
        XCTAssertEqual(socioEconomy.nbTrimTauxPleinDeterministic, 50)
        XCTAssertEqual(socioEconomy.persistenceSM.currentState , .modified)
    }

    func test_expensesUnderEvaluationRate() {
        XCTAssertEqual(SocioEconomyModelTest.socioEconomy.expensesUnderEvaluationRateDeterministic,
                       5)

        var socioEconomy = SocioEconomy(fromBundle : Bundle.module)
        socioEconomy.expensesUnderEvaluationRateDeterministic = 40
        XCTAssertEqual(socioEconomy.expensesUnderEvaluationRateDeterministic, 40)
        XCTAssertEqual(socioEconomy.persistenceSM.currentState , .modified)
    }

}
