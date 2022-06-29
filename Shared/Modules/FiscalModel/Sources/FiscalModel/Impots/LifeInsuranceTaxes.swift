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
        
        public var version                : Version
        public var rebatePerPerson        : Double // 4800.0 // euros
        public var prelevementLiberatoire : Double //  7.5 // % // avant le 27/09/2017
        public var datePivot              : Date   // Versements depuis le 27/09/2017
        public var seuil                  : Double // 150_000 // € seuil d'investissement après datePivot
        public var flatTax                : Double // 17.2 // % // après le 27/09/2017 au delà du seuil
    }
    
    // MARK: Properties
    
    public var model: Model

    public func prelevementLiberatoire(plusValueTaxable : Double,
                                       nbOfAdultAlive   : Int) -> Double {
        let lifeInsuranceRebate = model.rebatePerPerson * nbOfAdultAlive.double()
        if plusValueTaxable <= lifeInsuranceRebate {
            return 0
        } else {
            return plusValueTaxable * model.prelevementLiberatoire / 100.0
        }
    }
}
