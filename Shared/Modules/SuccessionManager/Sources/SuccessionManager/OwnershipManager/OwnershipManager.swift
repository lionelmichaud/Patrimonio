//
//  OwnershipManager.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/04/2021.
//

import Foundation
import os
import Ownership
import FamilyModel
import PatrimoineModel

let customLogOwnershipManager = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.OwnershipManager")

typealias MembersNameAgeProviderP = MembersNameProviderP & PersonAgeProviderP

struct OwnershipManager {
    
    // MARK: - Properties

    var family : MembersNameAgeProviderP
    var run    : Int
    var year   : Int

    // MARK: - Initializers

    /// - Parameters   :
    ///   - family: la famille dont il faut faire le bilan
    ///   - year: année des décès
    ///   - run: numéro du run en cours de calcul
    init(of family    : MembersNameAgeProviderP,
         atEndOf year : Int,
         run          : Int) {
        self.family = family
        self.year   = year
        self.run    = run
    }

}
