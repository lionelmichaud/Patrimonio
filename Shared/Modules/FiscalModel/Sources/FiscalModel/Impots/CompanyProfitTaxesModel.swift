//
//  CompanyProfitTaxesModel.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Impots sur les sociétés (SCI)
public struct CompanyProfitTaxesModel: Codable {
    
    // MARK: Nested types
    
    /// Ne contient aucune Class
    public struct Model: JsonCodableToBundleP, VersionableP, Equatable {
        static var defaultFileName : String = "CompanyProfitTaxesModel.json"
        public var version : Version
        public var rate    : Double // 15.0 // %
    }
    
    // MARK: Properties
    
    public var model: Model
    
    // MARK: Methods
    
    /// bénéfice net
    /// - Parameter brut: bénéfice brut
    public func net(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut - IS(brut)
    }
    
    /// impôts sur les bénéfices
    /// - Parameter brut: bénéfice brut
    public func IS(_ brut: Double) -> Double {
        guard brut >= 0.0 else {
            return 0.0
        }
        return brut * model.rate / 100.0
    }
}
