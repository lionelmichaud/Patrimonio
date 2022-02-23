//
//  LifeInsuranceClause.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

public enum ClauseError: String, Error {
    case invalidClause = "La clause de l'assurance vie n'est pas valide"
}

// MARK: - Clause bénéficiaire d'assurance vie

/// Clause bénéficiaire d'assurance vie
/// - Warning:
///   - le cas de plusieurs usufruitiers bénéficiaires n'est pas traité
///   - le cas de parts non égales entre nue-propriétaires bénéficiaires n'est pas traité
public struct LifeInsuranceClause: Codable, Hashable {

    // MARK: - Properties

    public var isOptional   : Bool = false
    public var isDismembered: Bool = false
    /// Bénéficiaires en PP
    public var fullRecipients: Owners = [] // PP si la clause n'est pas démembrée
    /// Bénéficiaire en UF
    public var usufructRecipient: String = "" // UF si la clause est démembrée
    // TODO: - traiter le cas des parts non égales chez les NP désignés dans la clause bénéficiaire
    //   => public var bareRecipients: Owners = [] // NP si la clause est démembrée
    /// Bénéficiaires en NP
    public var bareRecipients: [String] = [] // NP si la clause est démembrée
    
    public var isValid: Bool {
        switch (isOptional, isDismembered) {
            case (true, true):
                // une clause à option ne doit pas être démembrée
                return false

            case (true, false):
                // un seul donataire désigné en PP dans une clause à option (celui qui exerce l'option)
                return fullRecipients.count == 1 && fullRecipients.isvalid

            case (false, true):
                // il doit y avoir au moins 1 usufruitier et 1 nu-propriétaire
                return usufructRecipient.isNotEmpty && bareRecipients.isNotEmpty
                
            case (false, false):
                // Note: il peut ne pas y avoir de donataire
                return fullRecipients.isvalid
        }
    }
    
    public var invalidityCause: String? {
        guard !isValid else {
            return ""
        }
        switch (isOptional, isDismembered) {
            case (true, true):
                // une clause à option ne doit pas être démembrée
                return "Une clause à option ne doit pas être démembrée"

            case (true, false):
                // un seul donataire désigné en PP dans une clause à option (celui qui exerce l'option)
                if !fullRecipients.isvalid {
                    return "La liste des donataires de la clause à option n'est pas valide"
                }
                if fullRecipients.count != 1 {
                    return "La liste des donataires de la clause à option inclue plusieurs donataires"
                }

            case (false, true):
                if usufructRecipient.isEmpty {
                    return "La clause est démembrée en n'a pas de donataire en UF"
                }
                if bareRecipients.isEmpty {
                    return "La clause est démembrée en n'a pas de donataire en NP"
                }
                
            case (false, false):
                // Note: il peut ne pas y avoir de donataire
                if !fullRecipients.isvalid {
                    return "La liste des donataires de la clause n'est pas valide"
                }
        }
        return nil
    }
    
    // MARK: - Initializers
    
    public init() { }
}

extension LifeInsuranceClause: CustomStringConvertible {
    public var description: String {
        let header = """
        - Valide: \(isValid.frenchString)
        - Clause à option : \(isOptional.frenchString)
        - Clause démembrée: \(isDismembered.frenchString)

        """
        let fr =
            !isDismembered ? "   - Bénéficiaire en PP:\n      \(fullRecipients)" : ""
        let ur =
            isDismembered ? "   - Bénéficiaire en UF:\n      \(usufructRecipient) \n" : ""
        let br =
            isDismembered ? "   - Bénéficiaire en NP:\n      \(bareRecipients)" : ""
        return header + fr + ur + br
    }
}
