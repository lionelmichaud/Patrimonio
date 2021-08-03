//
//  AssetsCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Catégories de Actifs

/// Catégories de dépenses
enum AssetsCategory: String, PickableEnumP, Codable {
    case periodicInvests = "Invest. périodique"
    case freeInvests     = "Invest. libre"
    case realEstates     = "Immobilier"
    case scpis           = "SCPI"
    case sci             = "SCI"
    
    // properties
    
    var pickerString: String {
        return self.rawValue
    }
}
