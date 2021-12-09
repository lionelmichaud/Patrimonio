//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 07/12/2021.
//

import Foundation

public struct SemanticVersion: Codable, Equatable {

    // MARK: - Properties

    let major: Int
    let minor: Int
    let patch: Int

    // MARK: - Computed Properties

    public var asString: String {
        String(major) + "." + String(minor) + "." + String(patch)
    }
    public var nextMajor: SemanticVersion {
        SemanticVersion(major: major+1, minor: 0, patch: 0)
    }
    public var nextMinor: SemanticVersion {
        SemanticVersion(major: major, minor: minor+1, patch: 0)
    }

    // MARK: - Initializers

    public init(major: Int, minor: Int, patch: Int) {
        precondition(major >= 0, "SemanticVersion: major < 0")
        precondition(minor >= 0, "SemanticVersion: minor < 0")
        precondition(patch >= 0, "SemanticVersion: patch < 0")
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    public init?(version: String) {
        let parts = version.split(whereSeparator: { $0 == "." })
        guard parts.count == 3 else {
            return nil
        }
        
        if let major = Int(parts[0]), let minor = Int(parts[1]), let patch = Int(parts[2]) {
            assert(major >= 0, "SemanticVersion: major < 0")
            assert(minor >= 0, "SemanticVersion: minor < 0")
            assert(patch >= 0, "SemanticVersion: patch < 0")
            self.major = major
            self.minor = minor
            self.patch = patch
        } else {
            return nil
        }
    }

    // MARK: - Methods

    public func upToNextMajor(from version: String) -> Bool {
        guard let version = SemanticVersion(version: version) else {
            return false
        }
        return self < version.nextMajor
    }

    public func upToNextMinor(from version: String) -> Bool {
        guard let version = SemanticVersion(version: version) else {
            return false
        }
        return self < version.nextMajor
    }
}

extension SemanticVersion: CustomStringConvertible {
    public var description: String {
        "Version: " + asString
    }
}

extension SemanticVersion: Comparable {
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major < rhs.major {
            return true
        } else if lhs.major == rhs.major &&
                    lhs.minor < rhs.minor {
            return true
        } else if lhs.major == rhs.major &&
                    lhs.minor == rhs.minor &&
                    lhs.patch < rhs.patch {
            return true
        } else {
            return false
        }
    }
}
