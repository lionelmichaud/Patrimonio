//
//  NameableValuableArrayTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 17/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
import AppFoundation
import Persistable
@testable import NamedValue

class NameableValuableArrayTests: XCTestCase {
    
    struct Item: NameableValuableP, Identifiable, Codable, Equatable {
        var id   = UUID()
        var name : String
        
        func value(atEndOf year: Int) -> Double {
            Double(year)
        }
    }
    
    static let names: [String] =
        [
            "Item 1",
            "Item 2",
            "Item 3",
            "Item 4"
        ]
    static var tableNV = [Item]()
    
    struct TableOfItems: NameableValuableArrayP {
        private enum CodingKeys: CodingKey { // swiftlint:disable:this nesting
            case items
        }

        var items: [Item]
        var persistenceSM = PersistenceStateMachine(initialState : .created)
        var persistenceState : PersistenceState = .created
        var currentValue     : Double = 0
        var description: String {
            items.description
        }
        
        init(fileNamePrefix: String) {
            self.items = NameableValuableArrayTests.names.map {
                NameableValuableArrayTests.Item(name: fileNamePrefix + $0)
            }
        }
        init(for aClass: AnyClass, fileNamePrefix: String) {
            self.init(fileNamePrefix: fileNamePrefix)
        }
    }
    
    static var tableOfItems = TableOfItems(fileNamePrefix: "Test_")
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        NameableValuableArrayTests.tableNV = NameableValuableArrayTests.names.map { Item(name: $0) }
        NameableValuableArrayTests.tableOfItems = TableOfItems(fileNamePrefix: "Test_")
    }
    
    func test_description() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        print("Test de [NameableValuableP].description")
        
        var str: String =
            String(describing: NameableValuableArrayTests.tableNV)
            .withPrefixedSplittedLines("  ")
        print(str)

        str =
            String(describing: NameableValuableArrayTests.tableOfItems)
            .withPrefixedSplittedLines("  ")
        print(str)
    }
    
    func test_sumOfValues() {
        let year = 2020
        XCTAssertEqual(Double(year * NameableValuableArrayTests.names.count),
                       NameableValuableArrayTests.tableNV.sumOfValues(atEndOf: year))
    }
    
    func test_value() {
        let year = 2020
        XCTAssertEqual(Double(year * NameableValuableArrayTests.names.count),
                       NameableValuableArrayTests.tableOfItems.value(atEndOf: year))
    }
    
    func test_namedValueTable() {
        let year = 2020
        XCTAssertEqual(Double(year * NameableValuableArrayTests.names.count),
                       NameableValuableArrayTests.tableOfItems.value(atEndOf: year))
        XCTAssertEqual(Double(CalendarCst.thisYear * NameableValuableArrayTests.names.count),
                       NameableValuableArrayTests.tableOfItems.currentValue)
        XCTAssertEqual("Test_Item 2",
                       NameableValuableArrayTests.tableOfItems[1].name)
        
        XCTAssertEqual(2024,
                       NameableValuableArrayTests.tableOfItems[1].value(atEndOf: 2024))

        let namedValueArray = NameableValuableArrayTests.tableOfItems.namedValueTable(atEndOf: year)
        XCTAssertEqual(Double(year * NameableValuableArrayTests.names.count),
                       namedValueArray.sum(for: \.value))
        
        XCTAssertEqual("Test_Item 2",
                       namedValueArray[1].name)
    }
}
