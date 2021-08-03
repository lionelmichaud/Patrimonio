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
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant1"]
        let prefixed: String = String(describing: clause).withPrefixedSplittedLines("  ")
        print(prefixed)
    }

    func test_clause_npn_valide() {
        var clause = LifeInsuranceClause()
        
        clause.isDismembered = false
        clause.fullRecipients = []
        XCTAssertFalse(clause.isValid)

        clause.isDismembered = true
        clause.usufructRecipient = ""
        clause.bareRecipients = []
        XCTAssertFalse(clause.isValid)
        
        clause.usufructRecipient = ""
        clause.bareRecipients = ["Lionel"]
        XCTAssertFalse(clause.isValid)
 
        clause.usufructRecipient = "Lionel"
        clause.bareRecipients = []
        XCTAssertFalse(clause.isValid)
}
    
    func test_clause_valide() {
        var clause = LifeInsuranceClause()
        
        clause.isDismembered = false
        clause.fullRecipients = ["Enfant1"]
        XCTAssertTrue(clause.isValid)
        print(clause)

        clause.isDismembered = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients = ["Enfant1"]
        XCTAssertTrue(clause.isValid)
        print(clause)
    }

}
