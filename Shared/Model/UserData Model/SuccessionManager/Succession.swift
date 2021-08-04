//
//  Succession.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 18/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Succession d'une personne

enum SuccessionKindEnum: String {
    case legal         = "Légale"
    case lifeInsurance = "Assurance Vie"
}

struct Succession: Identifiable {
    let id           = UUID()
    // nature
    let kind: SuccessionKindEnum
    // année de la succession
    let yearOfDeath  : Int
    // personne dont on fait la succession
    let decedentName : String
    // masses successorale
    let taxableValue : Double
    // liste des héritages par héritier
    let inheritances : [Inheritance]
    
    // dictionnaire des héritages net reçu par chaque héritier dans une succession
    var successorsInheritedNetValue: [String: Double] {
        inheritances.reduce(into: [:]) { counts, inheritance in
            counts[inheritance.personName, default: 0] += inheritance.net
        }
    }
    
    // somme des héritages reçus par les héritiers dans une succession
    var net: Double {
        inheritances.sum(for: \.net)
    }
    
    // somme des taxes payées par les héritiers dans une succession
    var tax: Double {
        inheritances.sum(for: \.tax)
    }
}
extension Succession: SuccessionCsvVisitableP {
    func accept(_ visitor: SuccessionCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}
extension Succession: CustomStringConvertible {
    public var description: String {
        """
        Type de succession:  \(kind.rawValue)
        Défunt:              \(decedentName)
        Année du décès:      \(yearOfDeath)
        Masses successorale: \(taxableValue.k€String)
        Héritiers:

        """
            + String(describing: inheritances)
            .withPrefixedSplittedLines("  ")
    }
}
extension Array where Element == Succession {
    // dictionnaire des héritages net reçu par chaque héritier sur un ensemble de successions
    var successorsInheritedNetValue: [String: Double] {
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
struct Inheritance {
    // héritier
    var personName: String
    // fraction de la masse successorale reçue en héritage
    var percent : Double // [0, 1]
    var brut    : Double
    var net     : Double
    var tax     : Double
}
extension Inheritance: SuccessionCsvVisitableP {
    func accept(_ visitor: SuccessionCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}
extension Inheritance: CustomStringConvertible {
    public var description: String {
        """
        Héritier:      \(personName)
        Pourcentage:   \(percent) %
        Héritage Brut: \(brut.k€String)
        Héritage Net:  \(net.k€String)
        Droits:        \(tax.k€String)

        """.withPrefixedSplittedLines("  ")
    }
}
