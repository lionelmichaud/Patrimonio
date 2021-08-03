//
//  Sex.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/04/2021.
//

import Foundation
import AppFoundation

// MARK: - Sexe
enum Sexe: Int, PickableEnumP, Codable {
    case male
    case female
    
    var displayString: String {
        switch self {
            case .male:
                return "M."
            case .female:
                return "Mme"
        }
    }
    var pickerString: String {
        switch self {
            case .male:
                return "Homme"
            case .female:
                return "Femme"
        }
    }
}
