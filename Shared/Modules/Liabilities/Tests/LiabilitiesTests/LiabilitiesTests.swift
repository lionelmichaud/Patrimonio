import XCTest
@testable import Liabilities

final class LiabilitiesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Liabilities().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
