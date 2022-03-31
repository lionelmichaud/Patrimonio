//
//  Liability.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue
import Ownership

public typealias DebtArray = ArrayOfNameableValuable<Debt>

// MARK: - Stock de dette incrémentable ou diminuable
/// stock de dette incrémentable ou diminuable
public struct Debt: Codable, Identifiable, NameableValuableP, OwnableP {
    
    // MARK: - Type Properties

    public static let prototype = Debt()

    // MARK: - Properties

    public var id   = UUID()
    public var name : String = ""
    public var note : String = ""
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    public var ownership : Ownership = Ownership()
    public var value     : Double = 0
    
    // MARK: - Initializers
    
    public init(name             : String = "",
                note             : String = "",
                value            : Double = 0,
                delegateForAgeOf : ((_ name : String, _ year : Int) -> Int)? = nil) {
        self.name = name
        self.note = note
        self.ownership.setDelegateForAgeOf(delegate: delegateForAgeOf)
        self.value = value
    }
    
    // MARK: - Methods
    
    /// Valeur résiduelle courante de la dette
    /// - Parameter year: année courante
    /// - Returns: valeur négative
    public func value (atEndOf year: Int) -> Double {
        return value
    }
    public mutating func setValue(to value: Double) {
        self.value = value
    }
    public mutating func increase(by thisAmount: Double) {
        value += thisAmount
    }
    public mutating func decrease(by thisAmount: Double) {
        value -= thisAmount
    }
}

// MARK: Extensions
extension Debt: Comparable {
    public static func < (lhs: Debt, rhs: Debt) -> Bool {
        (lhs.name < rhs.name)
    }
}

extension Debt: CustomStringConvertible {
    public var description: String {
        """
        DETTE: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
          valeur: \(value.€String)
        """
    }
}
