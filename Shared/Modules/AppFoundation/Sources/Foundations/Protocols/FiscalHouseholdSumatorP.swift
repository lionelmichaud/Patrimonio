//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 02/09/2021.
//

import Foundation

// MARK: - DI: Protocol de service d'itération sur les membres du foyer fiscal dans la famille

public protocol FiscalHouseholdSumatorP {
    func sum(atEndOf year : Int,
             memberValue  : (String) -> Double) -> Double
}
