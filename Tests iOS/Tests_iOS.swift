//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Lionel MICHAUD on 18/04/2021.
//

import XCTest
//@testable import Numerics

class Tests_iOS: XCTestCase { // swiftlint:disable:this type_name
//    static let data: NamedValueArray =
//        [
//            (name: "Item 1", value: 1.0),
//            (name: "Item 2", value: 2.0),
//            (name: "Item 3", value: 3.0),
//            (name: "Item 4", value: 4.0)
//        ]

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation
        //- required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
//        let app = XCUIApplication()
//        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func test_truc() {

    }

    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
    }
}
