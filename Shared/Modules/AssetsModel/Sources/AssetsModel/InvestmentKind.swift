//
//  InvestmentType.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Ownership

// MARK: - Type d'investissement

public enum InvestementKind: Codable {
    case lifeInsurance (periodicSocialTaxes: Bool = true,
                        clause: Clause = Clause())
    case pea
    case other
    
    public static var allCases: [InvestementKind] {
        return [.lifeInsurance(), .pea, .other]
    }
    
    public var rawValue: Int {
        rawValueGeneric(of: self)
    }
    
    public var isValid: Bool {
        switch self {
            case .lifeInsurance(_ , let clause):
                return clause.isValid
            default:
                return true
        }
    }

    public var isLifeInsurance: Bool {
        switch self {
            case .lifeInsurance(_ , _):
                return true
            default:
                return false
        }
    }
}

// MARK: - Extensions

extension InvestementKind: CustomStringConvertible {
    public var description: String {
        switch self {
            case let .lifeInsurance(periodicSocialTaxes, clause):
                return
                    """
                    Assurance Vie:
                    - Prélèvement périodique des contributions sociales: \(periodicSocialTaxes.frenchString)
                    - Clause bénéficiaire:
                    \(clause.description.withPrefixedSplittedLines("  "))
                    """
            default:
                return pickerString
        }
    }
}

extension InvestementKind: PickableIdentifiableEnumP {
    public var id: Int {
        return self.rawValue
    }
    
    public var pickerString: String {
        switch self {
            case .lifeInsurance:
                return "Assurance Vie"
            case .pea:
                return "PEA"
            case .other:
                return "Autre"
        }
    }
}
