//
//  AppVersion.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

public struct AppVersion: Codable, VersionableP {
    
    // MARK: - Singleton
    
    public static let shared   = AppVersion()
    public static let fileName = "AppVersion.json"
    
    // MARK: - Properties
    
    public var version         : Version
    public var revisionHistory : [Version]
    
    // MARK: - Static Methods
    
    private init() {
        self = Bundle.main.loadFromJSON(AppVersion.self,
                                        from                 : AppVersion.fileName,
                                        dateDecodingStrategy : .iso8601,
                                        keyDecodingStrategy  : .useDefaultKeys)
        version.initializeWithBundleValues()
    }
    
    public var name: String? {
        version.name
    }
    
    public var theVersion : String? {
        version.version
    }
    public var date    : Date? {
        version.date
    }
    public var comment : String? {
        version.comment
    }
}
