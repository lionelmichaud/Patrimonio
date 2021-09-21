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
///   - le cas de plusieurs usufruitiers n'est pas traité
///   - le cas de parts non égales entre nue-propriétaires n'est pas traité
public struct LifeInsuranceClause: Codable, Hashable {
    public var isOptional   : Bool = false
    public var isDismembered: Bool = false
    // bénéficiaire en PP
    public var fullRecipients: Owners = [] // PP si la clause n'est pas démembrée
    // bénéficiaire en UF
    public var usufructRecipient: String = ""
    // bénéficiaire en NP
    public var bareRecipients: [String] = [ ]
    
    public var isValid: Bool {
        if isDismembered {
            return usufructRecipient.isNotEmpty && bareRecipients.isNotEmpty
        } else {
            return fullRecipients.isNotEmpty
        }
    }
    
    public init() { }
}

extension LifeInsuranceClause: CustomStringConvertible {
    public var description: String {
        let header = """
        - Valide:    \(isValid.frenchString)
        - Démembrée: \(isDismembered.frenchString)

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
