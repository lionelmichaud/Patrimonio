//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 10/08/2021.
//

import XCTest
@testable import LifeExpense

final class LifeExpenseCategoryTests: XCTestCase {
    
    // MARK: Tests
    
    func test_category() {
        let category = "Loisirs"
        XCTAssertEqual(LifeExpenseCategory.category(of: category), .loisirs)
    }
}
