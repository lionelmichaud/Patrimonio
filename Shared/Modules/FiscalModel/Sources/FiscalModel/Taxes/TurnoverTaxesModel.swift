//
//  TurnoverTaxesModel.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Charges sociales sur chiffre d'affaire
public struct TurnoverTaxesModel: Codable {
    
    // MARK: Nested types
    
    public struct Model: JsonCodableToBundleP, VersionableP {
        public static var defaultFileName : String = "TurnoverTaxesModel.json"
        public var version: Version
        public var URSSAF : Double // 24 // %
        var total  : Double {
            URSSAF // %
        }
    }
    
    // MARK: Properties
    
    public var model: Model
    
    // MARK: Methods
    
    /// chiffre d'affaire net de charges sociales
    /// - Parameter brut: chiffre d'affaire brut
    public func net(_ brut: Double) -> Double {
        guard brut > 0.0 else {
            return 0.0
        }
        return brut - socialTaxes(brut)
    }
    
    /// charges sociales sur le chiffre d'affaire brut
    /// - Parameter brut: chiffre d'affaire brut
    func socialTaxes(_ brut: Double) -> Double {
        guard brut > 0.0 else {
            return 0.0
        }
        return brut * model.URSSAF / 100.0
    }
}
