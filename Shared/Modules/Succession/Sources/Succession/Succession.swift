//
//  Succession.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 18/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Succession d'une personne

public enum SuccessionKindEnum: String {
    case legal         = "Légale"
    case lifeInsurance = "Assurance Vie"
}

public struct Succession: Identifiable {
    
    // MARK: - Propeties
    
    public let id           = UUID()
    // nature
    public let kind: SuccessionKindEnum
    // année de la succession
    public let yearOfDeath  : Int
    // personne dont on fait la succession
    public let decedentName : String
    // masses successorale
    public let taxableValue : Double
    // liste des héritages par héritier
    public let inheritances : [Inheritance]
    
    // dictionnaire des héritages net reçu par chaque héritier dans une succession
    var successorsInheritedNetValue: [String: Double] {
        inheritances.reduce(into: [:]) { counts, inheritance in
            counts[inheritance.personName, default: 0] += inheritance.net
        }
    }
    
    // somme des héritages reçus par les héritiers dans une succession
    public var net: Double {
        inheritances.sum(for: \.net)
    }
    
    // somme des taxes payées par les héritiers dans une succession
    public var tax: Double {
        inheritances.sum(for: \.tax)
    }
    
    // MARK: - Initializer
    
    public init(kind         : SuccessionKindEnum,
                yearOfDeath  : Int,
                decedentName : String,
                taxableValue : Double,
                inheritances : [Inheritance]) {
        self.kind = kind
        self.yearOfDeath = yearOfDeath
        self.decedentName = decedentName
        self.taxableValue = taxableValue
        self.inheritances = inheritances
    }
}
extension Succession: SuccessionCsvVisitableP {
    public func accept(_ visitor: SuccessionCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}
extension Succession: CustomStringConvertible {
    public var description: String {
        ("""
        Type de succession:  \(kind.rawValue)
        Défunt:              \(decedentName)
        Année du décès:      \(yearOfDeath)
        Masses successorale: \(taxableValue.k€String)
        Héritiers:

        """
            + String(describing: inheritances))
            .withPrefixedSplittedLines("  ")
    }
}
extension Array where Element == Succession {
    // dictionnaire des héritages net reçu par chaque héritier sur un ensemble de successions
    public var successorsInheritedNetValue: [String: Double] {
        var globalDico: [String: Double] = [:]
        self.forEach { succession in
            let dico = succession.successorsInheritedNetValue
            for name in dico.keys {
                if globalDico[name] != nil {
                    globalDico[name]! += dico[name]!
                } else {
                    globalDico[name] = dico[name]
                }
            }
        }
        return globalDico
    }
}

// MARK: - Héritage d'une personne
public struct Inheritance {
    
    // MARK: - Propeties
    
    // héritier
    public var personName: String
    // fraction de la masse successorale reçue en héritage
    public var percent : Double // [0, 1]
    public var brut    : Double
    public var net     : Double
    public var tax     : Double
    
    // MARK: - Initializer
    
    public init(personName : String,
                percent    : Double,
                brut       : Double,
                net        : Double,
                tax        : Double) {
        self.personName = personName
        self.percent = percent
        self.brut = brut
        self.net = net
        self.tax = tax
    }
}
extension Inheritance: SuccessionCsvVisitableP {
    public func accept(_ visitor: SuccessionCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}
extension Inheritance: CustomStringConvertible {
    public var description: String {
        """
        Héritier:      \(personName)
        Pourcentage:   \(percent * 100) %
        Héritage Brut: \(brut.k€String)
        Héritage Net:  \(net.k€String)
        Droits:        \(tax.k€String)

        """.withPrefixedSplittedLines("  ")
    }
}