//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 02/04/2022.
//

import Foundation

/// Règles de validité d'un nombre
public enum DoubleValidityRule {
    case none
    case poz
    case noz
    case positive
    case negative
    case lessThan(limit: Double)
    case lessThanOrEqualTo(limit: Double)
    case greaterThan(limit: Double)
    case greaterThanOrEqualTo(limit: Double)

    public func isValid(number: Double) -> Bool {
        switch self {
            case .none:
                return true
            case .poz:
                return number >= 0
            case .noz:
                return number <= 0
            case .positive:
                return number > 0
            case .negative:
                return number < 0
            case .lessThan(let limit):
                return number < limit
            case .lessThanOrEqualTo(let limit):
                return number <= limit
            case .greaterThan(let limit):
                return number > limit
            case .greaterThanOrEqualTo(let limit):
                return number >= limit
        }
    }
}

/// Règles de validité d'un nombre
public enum IntegerValidityRule {
    case none
    case poz
    case noz
    case positive
    case negative
    case lessThan(limit: Int)
    case lessThanOrEqualTo(limit: Int)
    case greaterThan(limit: Int)
    case greaterThanOrEqualTo(limit: Int)

    public func isValid(number: Int) -> Bool {
        switch self {
            case .none:
                return true
            case .poz:
                return number >= 0
            case .noz:
                return number <= 0
            case .positive:
                return number > 0
            case .negative:
                return number < 0
            case .lessThan(let limit):
                return number < limit
            case .lessThanOrEqualTo(let limit):
                return number <= limit
            case .greaterThan(let limit):
                return number > limit
            case .greaterThanOrEqualTo(let limit):
                return number >= limit
        }
    }
}

/// Règles de validité d'un String
public enum StringValidityRule {
    case none
    case notEmpty
    case lessThan(character: Int)
    case lessThanOrEqualTo(character: Int)
    case greaterThan(character: Int)
    case greaterThanOrEqualTo(character: Int)

    public func isValid(text: String) -> Bool {
        switch self {
            case .none:
                return true
            case .notEmpty:
                return !text.isEmpty
            case .lessThan(let character):
                return text.count < character
            case .lessThanOrEqualTo(let character):
                return text.count <= character
            case .greaterThan(let character):
                return text.count > character
            case .greaterThanOrEqualTo(let character):
                return text.count >= character
        }
    }
}
