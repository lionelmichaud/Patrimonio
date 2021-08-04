//
//  Config.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

public struct AppSettings: Decodable {
    
    // MARK: - Singleton
    
    public static let shared = AppSettings()
    
    // MARK: - Properties

    var templateDir     : String
    var imageDir        : String
    var tableDir        : String
    public var allPersonsLabel : String
    public var adultsLabel     : String

    // MARK: - Static Methods
    
    func csvPath(_ simulationTitle: String) -> String {
        simulationTitle + "/" + AppSettings.shared.tableDir + "/"
    }
    
    func imagePath(_ simulationTitle: String) -> String {
        simulationTitle + "/" + AppSettings.shared.imageDir + "/"
    }

    func templatePath() -> String {
        "Application support/" + AppSettings.shared.templateDir + "/"
    }

    private init() {
        self = Bundle.main.loadFromJSON(AppSettings.self,
                                        from                 : "AppSettings.json",
                                        dateDecodingStrategy : .iso8601,
                                        keyDecodingStrategy  : .useDefaultKeys)
    }
}