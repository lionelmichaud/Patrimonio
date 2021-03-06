//
//  LifeEvent.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Evénement de vie

enum LifeEvent: String, PickableEnum, Codable {
    case debutEtude         = "Début des études supérieurs"
    case independance       = "Indépendance financière"
    case cessationActivite  = "Fin d'activité professionnelle"
    case liquidationPension = "Liquidation de pension"
    case dependence         = "Dépendance"
    case deces              = "Décès"

    // MARK: - Computed Properties
    
    var pickerString: String {
        return self.rawValue
    }
    
    // True si l'événement est spécifique des Adultes
    var isAdultEvent: Bool {
        switch self {
            case .cessationActivite,
                 .liquidationPension,
                 .dependence:
                return true
            
            default:
                return false
        }
    }

    // True si l'événement est spécifique des Enfant
    var isChildEvent: Bool {
        switch self {
            case .debutEtude,
                 .independance:
                return true
            
            default:
                return false
        }
    }
}

// MARK: - Groupes de personnes

enum GroupOfPersons: String, PickableEnum, Codable {
    case allAdults    = "Tous les Adultes"
    case allChildrens = "Tous les Enfants"
    case allPersons   = "Toutes les Personnes"
    
    // MARK: - Computed Properties
    
    var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Date au plus tôt ou au plus tard

enum SoonestLatest: String, PickableEnum, Codable {
    case soonest = "Date au plus tôt"
    case latest  = "Date au plus tard"
    
    // MARK: - Computed Properties
    
    var pickerString: String {
        return self.rawValue
    }
}
