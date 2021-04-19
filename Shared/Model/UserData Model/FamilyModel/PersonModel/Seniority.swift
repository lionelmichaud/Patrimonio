//
//  Seniority.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/04/2021.
//

import Foundation
import AppFoundation

// MARK: - Seniority
enum Seniority: Int, PickableEnum {
    case adult
    case enfant
    
    var displayString: String {
        switch self {
            case .adult:
                return "(adulte)"
            case .enfant:
                return "(enfant)"
        }
    }
    var pickerString: String {
        switch self {
            case .adult:
                return "Adulte"
            case .enfant:
                return "Enfant"
        }
    }
}
