//
//  FinancialRevenuTaxesModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Charges sociales sur revenus financiers (dividendes, plus values, loyers...)
public struct FinancialRevenuTaxesModel: Codable, Equatable {
    
    // MARK: Nested types
    
    /// Ne contient aucune Class
    public struct Model: JsonCodableToBundleP, VersionableP, Equatable {
        static var defaultFileName : String = "FinancialRevenuTaxesModel.json"
        public var version      : Version
        public var CRDS         : Double // 0.5 // %
        public var CSG          : Double // 9.2 // %
        public var prelevSocial : Double // 7.5  // %
        var total: Double {
            CRDS + CSG + prelevSocial // %
        }
    }
    
    // MARK: Properties
    
    public var model: Model
    
    // MARK: Methods
    
    /// revenus financiers nets de charges sociales
    /// - Parameter brut: revenus financiers bruts
    public func net(_ brut: Double) -> Double {
        return brut - socialTaxes(brut)
    }
    
    /// charges sociales sur les revenus financiers
    /// - Parameter brut: revenus financiers bruts
    public func socialTaxes(_ brut: Double) -> Double {
        guard brut > 0.0 else {
            return 0.0
        }
        return brut * model.total / 100.0
    }
    
    /// revenus financiers bruts avant charges sociales
    /// - Parameter net: revenus financiers nets
    public func brut(_ net: Double) -> Double {
        guard net >= 0.0 else {
            return net
        }
        return net / (1.0 - model.total / 100.0)
    }
}
