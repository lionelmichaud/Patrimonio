//
//  Donation.swift
//  
//
//  Created by Lionel MICHAUD on 22/02/2022.
//

import Foundation
import AppFoundation

/// Donation d'un bien par une personne
public struct Donation: Codable, Hashable {
    public var atEndOfYear : Int = CalendarCst.thisYear
    public var clause      : LifeInsuranceClause

    public var isValid: Bool {
        clause.isValid && clause.isOptional == false
    }

    public var invalidityCause: String? {
        if clause.isOptional == false {
            return "Une clause de donation ne peut pas être à option"
        } else {
            return clause.invalidityCause
        }
    }

    // MARK: - Initializers

    init() {
        clause = LifeInsuranceClause()
        clause.isOptional = false
    }
}

extension Donation: CustomStringConvertible {
    public var description: String {
        clause.description
    }
}
