//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import XCTest
@testable import AppFoundation

class VersionTest: XCTestCase {

    func test_toVersion() {
        var version = Version.toVersion(major: 1, minor: 2, patch: 3)
        XCTAssertEqual(version, "1.2.3")
        version = Version.toVersion(major: 1, minor: 2, patch: nil)
        XCTAssertEqual(version, "1.2")
    }

    func test_fromVersion() {
        let version = Version(name: "test",
                              version: "1.2.3",
                              date: Date.now,
                              comment: "comment")

        let major = version.major
        XCTAssertNotNil(major)
        XCTAssertEqual(major, 1)

        let minor = version.minor
        XCTAssertNotNil(minor)
        XCTAssertEqual(minor, 2)

        let patch = version.patch
        XCTAssertNotNil(patch)
        XCTAssertEqual(patch, 3)
    }
}
