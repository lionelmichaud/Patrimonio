//
//  Version.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol Versionable pour versionner des données

public protocol Versionable {
    var version : Version { get set }
}

// MARK: - Versioning

///  - Note: [Reference](https://en.wikipedia.org/wiki/Software_versioning)
public struct Version: Codable {
    
    // MARK: - Properties
    
    public var name    : String?
    public var version : String? // "Major.Minor.Patch"
    public var date    : Date?
    public var comment : String?
    
    // MARK: - Computed Properties
    
    public var major   : Int? {
        guard let version = version else { return nil }
        if let major = version.split(whereSeparator: { $0 == "." }).first {
            return Int(major)
        } else {
            return nil
        }
    }
    public var minor   : Int? {
        guard let version = version else { return nil }
        let parts = version.split(whereSeparator: { $0 == "." })
        if parts.count >= 1 {
            return Int(parts[1])
        } else {
            return nil
        }
    }
    public var patch   : Int? {
        guard let version = version else { return nil }
        let parts = version.split(whereSeparator: { $0 == "." })
        if parts.count >= 2 {
            return Int(parts[2])
        } else {
            return nil
        }
    }
    
    // MARK: - Static Methods
    
    public static func toVersion(major : Int,
                                 minor : Int,
                                 patch : Int?) -> String {
        if let patch = patch {
            return String(major) + "." + String(minor) + "." + String(patch)
        } else {
            return String(major) + "." + String(minor)
        }
    }
    
    // MARK: - Methods
    
    public mutating func initializeWithBundleValues() {
        if version == nil {
            version = Bundle.mainAppVersion
        }
        if name == nil {
            name = Bundle.mainAppName
        }
        if date == nil {
            date = Bundle.mainBuildDate
        }
    }
}
