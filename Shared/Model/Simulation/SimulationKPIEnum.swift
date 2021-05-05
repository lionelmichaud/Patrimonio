//
//  SimulationKPIEnum.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import Foundation
import AppFoundation

// MARK: - Enumération des KPI

enum SimulationKPIEnum: Int, PickableEnum, Codable, Hashable {
    case minimumAsset = 0
    case assetAt1stDeath
    case assetAt2ndtDeath
    
    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .minimumAsset:
                return "Actif Financier Minimum"
            case .assetAt1stDeath:
                return "Actif au Premier Décès"
            case .assetAt2ndtDeath:
                return "Actif au Dernier Décès"
        }
    }
    
    var note: String {
        switch self {
            case .minimumAsset:
                return "Valeur minimale atteinte dans le temps pour la somme des actifs financiers (hors immobilier physique)"
            case .assetAt1stDeath:
                return "Valeur totale des actifs financiers NET (hors immobilier d'habitation) au premier décès"
            case .assetAt2ndtDeath:
                return "Valeur totale des actifs financiers NET (hors immobilier d'habitation) au second décès"
        }
    }
}
