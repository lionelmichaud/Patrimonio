//
//  Donation.swift
//  
//
//  Created by Lionel MICHAUD on 22/02/2022.
//

import Foundation
import AppFoundation
import Ownership

/// Donation d'un bien par une personne donateur à des personnes donataires
public struct Donation: Codable, Hashable {
    /// Année à la fin de laquelle la donation est effectuée
    public var atEndOfYear : Int = CalendarCst.thisYear
    /// Désigne les donataires
    public var clause      : Clause

    public var isValid: Bool {
        clause.isValid && !clause.isOptional
    }

    public var invalidityCause: String? {
        if clause.isOptional == false {
            return "Une clause de donation ne peut pas être à option"
        } else {
            return clause.invalidityCause
        }
    }

    // MARK: - Initializers

    public init() {
        clause = Clause()
        // une donation ne peut pas être optionnelle
        clause.isOptional = false
    }
}

extension Donation: CustomStringConvertible {
    public var description: String {
        let header = """
        - Valide: \(isValid.frenchString) \(isValid ? "" : " cause: ") \(invalidityCause ?? "")
        - Clause démembrée: \(clause.isDismembered.frenchString)

        """
        let fr =
            !clause.isDismembered ? "   - Bénéficiaire en PP:\n      \(clause.fullRecipients)" : ""
        let ur =
            clause.isDismembered ? "   - Bénéficiaire en UF:\n      \(clause.usufructRecipient) \n" : ""
        let br =
            clause.isDismembered ? "   - Bénéficiaire en NP:\n      \(clause.bareRecipients)" : ""
        return header + fr + ur + br
    }
}
