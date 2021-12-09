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
        let version = Version.toVersion(major: 1,
                                        minor: 2,
                                        patch: 3)
        XCTAssertEqual(version, "1.2.3")
    }

    func test_fromVersion() {
        let date = Date.now
        let vers = Version.toVersion(major: 1,
                                     minor: 2,
                                     patch: 3)
        var version = Version()
            .named("test")
            .dated(date)
            .versioned(vers)
            .commented(with: "comment")
        XCTAssertEqual(version.name, "test")
        XCTAssertEqual(version.date, date)
        XCTAssertEqual(version.version, vers)
        XCTAssertEqual(version.comment, "comment")
        print(version)

        let major = version.major
        XCTAssertNotNil(major)
        XCTAssertEqual(major, 1)

        let minor = version.minor
        XCTAssertNotNil(minor)
        XCTAssertEqual(minor, 2)

        let patch = version.patch
        XCTAssertNotNil(patch)
        XCTAssertEqual(patch, 3)
        
        version = Version()
            .versioned(major: 1,
                       minor: 2,
                       patch: 3)
        XCTAssertEqual(version.version, vers)
    }
    
    func test_semanticVersion () throws {
        let version = Version()
            .versioned(major: 1,
                       minor: 2,
                       patch: 3)
        let semanticVersion = try XCTUnwrap(version.semanticVersion)
        XCTAssertEqual(semanticVersion.major, 1)
        XCTAssertEqual(semanticVersion.minor, 2)
        XCTAssertEqual(semanticVersion.patch, 3)
    }
    
    func test_invalid() {
        let version = Version()
        XCTAssertNil(version.major)
        XCTAssertNil(version.minor)
        XCTAssertNil(version.patch)
    }
}
