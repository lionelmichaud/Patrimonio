import XCTest
@testable import BalanceSheet

final class BalanceSheetTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BalanceSheet().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}