//
//  Family+Protocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - DI: Protocol de service de fourniture de la liste des noms des membres de la famille

protocol MembersNameProviderP {
    var membersName  : [String] { get }
    var adultsName   : [String] { get }
    var childrenName : [String] { get }
}

// MARK: - DI: Protocol de service d'itération sur les membres du foyer fiscal dans la famille

protocol FiscalHouseholdSumatorP {
    func sum(atEndOf year : Int,
             memberValue  : (String) -> Double) -> Double
}
