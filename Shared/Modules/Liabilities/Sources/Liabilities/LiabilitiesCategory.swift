//
//  LiabilitiesCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Catégories de Actifs

/// Catégories de dépenses
public enum LiabilitiesCategory: String, PickableEnumP, Codable {
    case debts = "Dettes"
    case loans = "Emprunts"
    
    // properties
    
    public var pickerString: String {
        return self.rawValue
    }
}
