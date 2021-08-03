//
//  SimulationMode.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

public enum SimulationModeEnum: String, PickableEnumP, Codable, Hashable {
    case deterministic = "Déterministe"
    case random        = "Aléatoire"
    
    // properties
    
    public var pickerString: String {
        return self.rawValue
    }
}
