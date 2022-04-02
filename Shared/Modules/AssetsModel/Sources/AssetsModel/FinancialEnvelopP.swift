//
//  FinancialEnvelop.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Ownership

// MARK: Protocol d'enveloppe financière

public protocol FinancialEnvelopP: OwnableP {
    var type            : InvestementKind { get set }
    var isLifeInsurance : Bool { get }
    var clause          : Clause? { get }
    
    func isOpen(in year: Int) -> Bool
}

public extension FinancialEnvelopP {
    var isLifeInsurance: Bool {
        switch type {
            case .lifeInsurance:
                return true
            default:
                return false
        }
    }
    var clause: Clause? {
        switch type {
            case .lifeInsurance(_, let clause):
                return clause
            default:
                return nil
        }
    }
    /// Retourne True si le `Type` d'investissement est valide & si le `Ownership` est valide
    var isValid: Bool {
        type.isValid && ownership.isValid
    }
}
