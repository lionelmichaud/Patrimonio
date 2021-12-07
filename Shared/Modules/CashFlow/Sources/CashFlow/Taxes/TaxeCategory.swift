//
//  TaxesCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/08/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Catégories de taxe

/// Catégories de dépenses
public enum TaxeCategory: String, PickableEnumP, Codable, Hashable {
    case irpp            = "IRPP"
    case isf             = "ISF"
    case legalSuccession = "Droits Succes. Légale"
    case liSuccession    = "Droits Succes. Ass. Vie"
    case socialTaxes     = "Prélev Sociaux"
    case localTaxes      = "Taxes Locales"

    // properties
    
    public var pickerString: String {
        return self.rawValue
    }
}
