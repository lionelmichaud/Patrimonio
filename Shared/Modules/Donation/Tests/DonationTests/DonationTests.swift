import XCTest
@testable import Donation

final class DonationTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Donation().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
