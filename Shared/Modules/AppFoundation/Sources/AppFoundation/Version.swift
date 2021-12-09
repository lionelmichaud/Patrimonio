//
//  Version.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol Versionable pour versionner des données

public protocol VersionableP {
    var version : Version { get set }
}

// MARK: - Versioning

///  - Note: [Reference](https://en.wikipedia.org/wiki/Software_versioning)

public struct Version: Codable {
    
    // MARK: - Properties
    
    public private(set) var name    : String?
    public private(set) var version : String?// "Major.Minor.Patch"
    public private(set) var date    : Date?
    public private(set) var comment : String?
    
    public var semanticVersion: SemanticVersion? {
        guard let version = version else {
            return nil
        }
        return SemanticVersion(version: version)
    }
    
    // MARK: - Initializers
    
    /// Initialiser à vide
    public init() {
    }
    
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
        if parts.count > 1 {
            return Int(parts[1])
        } else {
            return nil
        }
    }
    public var patch   : Int? {
        guard let version = version else { return nil }
        let parts = version.split(whereSeparator: { $0 == "." })
        if parts.count > 2 {
            return Int(parts[2])
        } else {
            return nil
        }
    }
    
    // MARK: - Static Methods
    
    public static func toVersion(major : Int,
                                 minor : Int,
                                 patch : Int) -> String {
        String(major) + "." + String(minor) + "." + String(patch)
    }
    
    // MARK: - Builders

     func named(_ name: String) -> Version {
        var new = self
        new.name = name
        return new
    }

    func dated(_ date: Date) -> Version {
        var new = self
        new.date = date
        return new
    }

    func commented(with comment: String) -> Version {
        var new = self
        new.comment = comment
        return new
    }

    func versioned(_ version: String) -> Version {
        var new = self
        new.version = version
        return new
    }
    
    func versioned(major : Int,
                   minor : Int,
                   patch : Int) -> Version {
        var new = self
        new.version = Version.toVersion(major: major,
                                        minor: minor,
                                        patch: patch)
        return new
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

extension Version: CustomStringConvertible {
    public var description: String {
        """

        Version:
          Nom: \(name ?? "?")
          Version: \(version ?? "?")
          Date: \(date?.stringLongDate ?? "?")
          Description: \(comment ?? "?")

        """
    }
}
