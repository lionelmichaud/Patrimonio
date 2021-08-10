//
//  Seniority.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/04/2021.
//

import Foundation
import AppFoundation

// MARK: - Seniority
public enum Seniority: Int, PickableEnumP {
    case adult
    case enfant
    
    public var displayString: String {
        switch self {
            case .adult:
                return "(adulte)"
            case .enfant:
                return "(enfant)"
        }
    }
    public var pickerString: String {
        switch self {
            case .adult:
                return "Adulte"
            case .enfant:
                return "Enfant"
        }
    }
}
