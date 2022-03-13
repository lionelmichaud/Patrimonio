//
//  InvestementTypeTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 07/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
import Ownership
@testable import AssetsModel

class InvestementTypeTests: XCTestCase {

    func test_description() throws {
        var inv: InvestementKind
        
        inv = .pea
        var str: String =
            String(describing: inv)
            .withPrefixedSplittedLines("  ")
        print(str)

        inv = .other
        str =
            String(describing: inv)
            .withPrefixedSplittedLines("  ")
        print(str)

        var clause = Clause()
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant1"]
        inv = .lifeInsurance(periodicSocialTaxes: true,
                             clause: clause)
        str =
            String(describing: inv)
            .withPrefixedSplittedLines("  ")
        print(str)
    }
}
