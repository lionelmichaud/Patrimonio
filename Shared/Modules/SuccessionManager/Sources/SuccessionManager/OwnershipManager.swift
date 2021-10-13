//
//  OwnershipManager.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/04/2021.
//

import Foundation
import FamilyModel

struct OwnershipManager {
    
    // MARK: - Properties

    var family : Family
    var run    : Int
    var year   : Int

    // MARK: - Initializers

    /// - Parameters   :
    ///   - family: la famille dont il faut faire le bilan
    ///   - year: année des décès
    ///   - run: numéro du run en cours de calcul
    init(of family    : Family,
         atEndOf year : Int,
         run          : Int) {
        self.family = family
        self.year   = year
        self.run    = run
    }

}
