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

public enum InvestementKind {
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

extension InvestementKind: Codable {
    // coding keys
    private enum CodingKeys: String, CodingKey {
        case lifeInsurance_taxes, lifeInsurance_clause, PEA, other
    }
    
    // error type
    enum InvestementTypeCodingError: Error {
        case decoding(String)
    }
    
    // decode
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        // decode .lifeInsurance
        if let valueTaxes = try? values.decode(Bool.self, forKey: .lifeInsurance_taxes) {
            if let valueClause = try? values.decode(Clause.self, forKey: .lifeInsurance_clause) {
                self = .lifeInsurance(periodicSocialTaxes: valueTaxes, clause: valueClause)
                return
            }
        }
        
        // decode .PEA
        if (try? values.decode(Bool.self, forKey: .PEA)) != nil {
            self = .pea
            return
        }
        
        // decode .other
        if (try? values.decode(Bool.self, forKey: .other)) != nil {
            self = .other
            return
        }
        
        throw InvestementTypeCodingError.decoding("Error decoding 'InvestementType' ! \(dump(values))")
    }
    
    // encode
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
            case .lifeInsurance(let periodicSocialTaxes, let clause):
                try container.encode(periodicSocialTaxes, forKey: .lifeInsurance_taxes)
                try container.encode(clause, forKey: .lifeInsurance_clause)
            case .pea:
                try container.encode(true, forKey: .PEA)
            case .other:
                try container.encode(true, forKey: .other)
        }
    }
}
