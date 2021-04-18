import XCTest
@testable import AppFoundation

final class MyAppFoundationTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AppFoundation().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample)
    ]
}
