//
//  InterestRateTypeTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 07/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import AssetsModel

class InterestRateTypeTests: XCTestCase {

    func test_description() throws {
        print("Test de InterestRateKind.description")
        
        var inv: InterestRateKind
        
        inv = .contractualRate(fixedRate: 5.0)
        var str: String =
            String(describing: inv)
            .withPrefixedSplittedLines("  ")
        print(str)
        
        inv = .marketRate(stockRatio: 10.0)
        str =
            String(describing: inv)
            .withPrefixedSplittedLines("  ")
        print(str)
    }
}
