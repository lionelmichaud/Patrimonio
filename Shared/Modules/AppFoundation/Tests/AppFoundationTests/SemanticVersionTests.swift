//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import XCTest
@testable import AppFoundation

class SemanticVersionTest: XCTestCase {
    
    func test_init_from_string() throws {
        let version = try XCTUnwrap(SemanticVersion(version: "1.2.3"))
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 2)
        XCTAssertEqual(version.patch, 3)
        XCTAssertEqual(version.asString, "1.2.3")
        
        XCTAssertNil(SemanticVersion(version: "1.2."))
        XCTAssertNil(SemanticVersion(version: "1."))
        XCTAssertNil(SemanticVersion(version: "1"))
        XCTAssertNil(SemanticVersion(version: ""))
        XCTAssertNil(SemanticVersion(version: "a.2.3"))
    }
    
    func test_description() {
        let version = SemanticVersion(major: 1, minor: 2, patch: 3)
        XCTAssertEqual(version.description, "Version: 1.2.3")
        print(version.description)
    }
    
    func test_compare() {
        let v123 = SemanticVersion(major: 1, minor: 2, patch: 3)
        XCTAssertTrue(v123 <= v123)

        let v124 = SemanticVersion(major: 1, minor: 2, patch: 4)
        XCTAssertTrue(v123 < v124)
        
        let v131 = SemanticVersion(major: 1, minor: 3, patch: 1)
        XCTAssertTrue(v123 < v131)
        
        let v211 = SemanticVersion(major: 2, minor: 1, patch: 1)
        XCTAssertTrue(v123 < v211)
        
        let v111 = SemanticVersion(major: 1, minor: 1, patch: 1)
        XCTAssertFalse(v123 < v111)
        
        let v011 = SemanticVersion(major: 0, minor: 1, patch: 1)
        XCTAssertFalse(v123 < v011)
        
        let v112 = SemanticVersion(major: 1, minor: 1, patch: 2)
        XCTAssertFalse(v123 < v112)
    }

    func test_upToNextMajor() {
        let v123 = SemanticVersion(major: 1, minor: 2, patch: 3)
        let next = v123.nextMajor
        XCTAssertEqual(next.asString, "2.0.0")
        XCTAssertTrue(SemanticVersion(version: "1.2.3")!.upToNextMajor(from: "1.2.3"))
        XCTAssertTrue(SemanticVersion(version: "1.9.9")!.upToNextMajor(from: "1.2.3"))
        XCTAssertFalse(SemanticVersion(version: "2.0.0")!.upToNextMajor(from: "1.2.3"))
    }

    func test_upToNextMinor() {
        let v123 = SemanticVersion(major: 1, minor: 2, patch: 3)
        let next = v123.nextMinor
        XCTAssertEqual(next.asString, "1.3.0")
        XCTAssertTrue(SemanticVersion(version: "1.2.9")!.upToNextMinor(from: "1.2.3"))
        XCTAssertFalse(SemanticVersion(version: "1.3.0")!.upToNextMinor(from: "1.2.3"))
    }
}
