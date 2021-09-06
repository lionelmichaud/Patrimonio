//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 06/09/2021.
//

import Foundation
import AppFoundation

/// Combinaisons possibles de séries sur le graphique de Bilan
public enum BalanceCombination: String, PickableEnumP {
    case assets      = "Actif"
    case liabilities = "Passif"
    case both        = "Tout"
    
    public var pickerString: String {
        return self.rawValue
    }
}
