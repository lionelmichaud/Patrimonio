//
//  Config.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

struct AppSettings: Decodable {
    
    // MARK: - Singleton
    
    static let shared = AppSettings()
    
    // MARK: - Properties

    var templateDir     : String
    var imageDir        : String
    var tableDir        : String
    var allPersonsLabel : String
    var adultsLabel     : String

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
