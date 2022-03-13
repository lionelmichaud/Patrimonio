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
    public let kind         : SuccessionKindEnum
    // année de la succession
    public let yearOfDeath  : Int
    // personne dont on fait la succession
    public let decedentName : String
    // masse successorale en valeure fiscale
    public let taxableValue : Double
    // liste des héritages par héritier
    public let inheritances : [Inheritance]
    
    // dictionnaire des héritages net reçu en cash par chaque héritier dans une succession
    var successorsReceivedNetValue: [String: Double] {
        inheritances.reduce(into: [:]) { counts, inheritance in
            counts[inheritance.successorName, default: 0] += inheritance.receivedNet
        }
    }
    
    // somme des héritages reçus par les héritiers dans une succession
    public var netFiscal: Double {
        inheritances.sum(for: \.netFiscal)
    }
    
    // somme des taxes payées par les héritiers dans une succession
    public var tax: Double {
        inheritances.sum(for: \.tax)
    }
    public var received      : Double {
        inheritances.sum(for: \.received)
    }
    public var receivedNet   : Double {
        inheritances.sum(for: \.receivedNet)
    }
    public var creanceRestit : Double {
        inheritances.sum(for: \.creanceRestit)
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
    
    // MARK: - Methods
    
    /// Créance de restitution fiscale de `name` inclue dans la succession `self`
    /// - Parameter name: nom de l'héritier
    /// - Returns: Créance de restitution fiscale
    public func creanceRestit(of name: String) -> Double {
        inheritances.reduce(0.0) { result, inheritance in
            result + (inheritance.successorName == name ? inheritance.creanceRestit : 0.0)
        }
//        var total = 0.0
//        inheritances.forEach { inheritance in
//            total += inheritance.successorName == name ? inheritance.creanceRestit : 0.0
//        }
//        return total
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
        Type de succession:         \(kind.rawValue)
        Défunt:                     \(decedentName)
        Année du décès:             \(yearOfDeath)
        Masse successorale taxable: \(taxableValue.k€String) (valeur fiscale)
        Héritiers:

        """ + String(describing: inheritances).withPrefixedSplittedLines("  "))
    }
}
extension Array where Element == Succession {
    // dictionnaire des héritages net reçu en cash par chaque héritier sur un ensemble de successions
    public var successorsReceivedNetValue: [String: Double] {
        var globalDico: [String: Double] = [:]
        self.forEach { succession in
            let dico = succession.successorsReceivedNetValue
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

public struct Inheritance: Hashable {
    
    // MARK: - Propeties
    
    // héritier
    public var successorName : String
    // évaluation de la valeur fiscale
    public var percentFiscal : Double // [0, 1] = brutFiscal / masse successorale
    public var brutFiscal    : Double // valeur fiscale
    public var abatFrac      : Double // [0, 1] de l'abattement fiscal maximum
    public var netFiscal     : Double // valeur fiscale
    public var tax           : Double
    // évaluation de la valeur réellement transmise en cash
    public var received      : Double
    public var receivedNet   : Double // net de taxes
    // créance de restitution de l'héritier envers le quasi-usufruitier
    public var creanceRestit : Double
    
    // MARK: - Initializer
    
    public init(personName    : String,
                percentFiscal : Double = 0.0,
                brutFiscal    : Double = 0.0,
                abatFrac      : Double = 0.0,
                netFiscal     : Double = 0.0,
                tax           : Double = 0.0,
                received      : Double = 0.0,
                receivedNet   : Double = 0.0,
                creanceRestit : Double = 0.0) {
        self.successorName = personName
        self.percentFiscal = percentFiscal
        self.brutFiscal    = brutFiscal
        self.abatFrac      = abatFrac
        self.netFiscal     = netFiscal
        self.tax           = tax
        self.received      = received
        self.receivedNet   = receivedNet
        self.creanceRestit = creanceRestit
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
        Héritier:        \(successorName)
        Pourcentage:     \(percentFiscal.percentNormString(digit: 1)) de la masse successorale
        Héritage Brut:   \(brutFiscal.k€String) (valeur fiscale)
        Abattement %:    \((abatFrac * 100.0).rounded()) % de l'abattement fiscal maximum
        Héritage Net:    \(netFiscal.k€String) (valeur fiscale)
        Taxes ou Droits: \(tax.k€String)
        Cash reçu:       \(received.k€String)
        Cash reçu net:   \(receivedNet.k€String)
        Créance de resti:\(creanceRestit.k€String)

        """
    }
}
