//
//  LifeInsuranceTaxes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Impôt sur les plus-values d'assurance vie-Assurance vies
/// Ne contient aucune Class
public struct LifeInsuranceTaxes: Codable, Equatable {
    
    // MARK: Nested types
    
    public struct Model: JsonCodableToBundleP, VersionableP, Equatable {
        public static var defaultFileName : String = "LifeInsuranceTaxesModel.json"
        
        public var version        : Version
        public var rebatePerPerson: Double // 4800.0 // euros
    }
    
    // MARK: Properties
    
    public var model: Model
}
