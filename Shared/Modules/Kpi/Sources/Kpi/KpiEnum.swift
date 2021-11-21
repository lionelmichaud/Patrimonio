//
//  KPIEnum.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import Foundation
import AppFoundation
import Persistence

// MARK: - Enumération des KPI

public enum KpiEnum: String, PickableEnumP, Codable, Hashable {
    case minimumAdultsAssetExcludinRealEstates = "Actif Financier Minimum"
    case assetAt1stDeath                       = "Actif au Premier Décès"
    case assetAt2ndtDeath                      = "Actif au Dernier Décès"
    case netSuccessionAt2ndDeath               = "Héritage net des enfants"
    case successionTaxesAt1stDeath             = "Droits suc. enfants 1er décès"
    case successionTaxesAt2ndDeath             = "Droits suc. enfants total"

    // properties
    
    public var pickerString: String {
        self.rawValue
    }
}
