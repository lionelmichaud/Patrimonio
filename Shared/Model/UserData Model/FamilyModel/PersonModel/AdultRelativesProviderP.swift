//
//  AdultRelativesProviderP.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/08/2021.
//

import Foundation
import LifeExpense

// MARK: - DI: Protocol de service de fourniture de l'époux d'un adulte

protocol AdultSpouseProviderP {
    func spouseOf(_ member: Adult) -> Adult?
}

typealias AdultRelativesProviderP = MembersCountProviderP & AdultSpouseProviderP
