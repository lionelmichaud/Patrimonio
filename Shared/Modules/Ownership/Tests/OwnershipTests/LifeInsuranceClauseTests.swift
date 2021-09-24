//
//  LifeInsuranceClauseTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 06/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import Ownership

class LifeInsuranceClauseTests: XCTestCase {

    func test_description() {
        print("Test de LifeInsuranceClause.description")
        var clause = LifeInsuranceClause()
        // clause sans option
        print("Clause sans option")
        clause.isOptional        = false
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant1"]
        var prefixed: String = String(describing: clause).withPrefixedSplittedLines("  ")
        print(prefixed)

        // clause à option
        print("Clause avec option")
        clause.isOptional        = true
        clause.isDismembered     = false
        clause.fullRecipients = [Owner(name: "Enfant1", fraction: 50),
                                 Owner(name: "Enfant2", fraction: 50)]
        clause.usufructRecipient = ""
        clause.bareRecipients    = []
        prefixed = String(describing: clause).withPrefixedSplittedLines("  ")
        print(prefixed)
    }
    
    func test_clause_sans_option_non_valide() {
        var clause = LifeInsuranceClause()
        
        clause.isOptional    = false
        clause.isDismembered = false
        clause.fullRecipients = []
        XCTAssertFalse(clause.isValid)
        
        clause.isOptional    = false
        clause.isDismembered = true
        clause.usufructRecipient = ""
        clause.bareRecipients = []
        XCTAssertFalse(clause.isValid)
        
        clause.isOptional    = false
        clause.isDismembered = true
        clause.usufructRecipient = ""
        clause.bareRecipients = ["Lionel"]
        XCTAssertFalse(clause.isValid)
        
        clause.isOptional    = false
        clause.isDismembered = true
        clause.usufructRecipient = "Lionel"
        clause.bareRecipients = []
        XCTAssertFalse(clause.isValid)
    }
    
    func test_clause_avec_option_non_valide() {
        var clause = LifeInsuranceClause()

        clause.isOptional    = true
        clause.isDismembered = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients = ["Enfant1"]
        XCTAssertFalse(clause.isValid)

        clause.isOptional    = true
        clause.isDismembered = false
        clause.fullRecipients = [Owner(name: "Enfant1", fraction: 40),
                                 Owner(name: "Enfant2", fraction: 40)]
        XCTAssertFalse(clause.isValid)
        print(clause)
    }
        
    func test_clause_sans_option_valide() {
        var clause = LifeInsuranceClause()
        
        clause.isOptional    = false
        clause.isDismembered = false
        clause.fullRecipients = [Owner(name: "Enfant1", fraction: 100)]
        XCTAssertTrue(clause.isValid)
        print(clause)

        clause.isOptional    = false
        clause.isDismembered = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients = ["Enfant1"]
        XCTAssertTrue(clause.isValid)
        print(clause)
    }

    func test_clause_avec_option_valide() {
        var clause = LifeInsuranceClause()
        
        clause.isOptional    = true
        clause.isDismembered = false
        clause.fullRecipients = [Owner(name: "Enfant1", fraction: 40),
                                 Owner(name: "Enfant2", fraction: 60)]
        XCTAssertTrue(clause.isValid)
        print(clause)
        
        clause.isOptional    = true
        clause.isDismembered = false
        clause.fullRecipients = [Owner(name: "Enfant1", fraction: 100)]
        XCTAssertTrue(clause.isValid)
        print(clause)
    }
}
