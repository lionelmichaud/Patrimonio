//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 18/01/2022.
//

import Foundation

// MARK: Protocol d'Item Valuable et Nameable

public protocol NameableValuableP {
    var name: String { get }
    func value(atEndOf year: Int) -> Double
}

// MARK: - Extensions de Array

public extension Array where Element: NameableValuableP {
    /// Somme de toutes les valeurs d'un Array
    ///
    /// Usage:
    ///
    ///     total = items.sumOfValues(atEndOf: 2020)
    ///
    /// - Returns: Somme de toutes les valeurs d'un Array
    func sumOfValues (atEndOf year: Int) -> Double {
        return reduce(.zero, {result, element in
            result + element.value(atEndOf: year)
        })
    }
}
