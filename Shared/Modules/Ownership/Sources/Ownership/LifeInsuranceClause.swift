//
//  LifeInsuranceClause.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Clause bénéficiaire d'assurance vie

/// Clause bénéficiaire d'assurance vie
/// - Warning:
///   - le cas de plusieurs usufruitiers bénéficiaires n'est pas traité
///   - le cas de parts non égales entre nue-propriétaires bénéficiaires n'est pas traité
public struct LifeInsuranceClause: Codable, Hashable {
    public var isOptional   : Bool = false
    public var isDismembered: Bool = false
    // bénéficiaire en PP
    public var fullRecipients: Owners = [] // PP si la clause n'est pas démembrée
    // bénéficiaire en UF
    public var usufructRecipient: String = "" // UF si la clause est démembrée
    // bénéficiaire en NP
    // TODO: - traiter le cas des parts non égales chez les NP de la clause bénéficiaire
    // public var bareRecipients: Owners = [] // NP si la clause est démembrée
    public var bareRecipients: [String] = [] // NP si la clause est démembrée
    
    public var isValid: Bool {
        switch (isOptional, isDismembered) {
            case (true, true):
                // une clause à option ne doit pas être démembrée
                return false
                
            case (false, true):
                return usufructRecipient.isNotEmpty && bareRecipients.isNotEmpty
                
            case (false, false):
                return fullRecipients.isNotEmpty && fullRecipients.isvalid

            case (true, false):
                // un seul donataire désigné en PP dans une clause à option (celui qui exerce l'option)
                return fullRecipients.count == 1 && fullRecipients.isvalid
        }
    }
    
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
