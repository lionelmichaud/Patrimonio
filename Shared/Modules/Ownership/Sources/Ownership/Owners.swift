//
//  Owners.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Numerics

// MARK: - Les droits de propriété d'un Owner

public struct Owner : Codable, Hashable {
    // MARK: - Properties
    
    public var name     : String = ""
    public var fraction : Double = 0.0 // % [0, 100] part de propriété
    var isValid  : Bool {
        name != ""
    }
    
    // MARK: - Initializer

    public init(name: String = "", fraction: Double = 0.0) {
        self.name = name
        self.fraction = fraction
    }
    
    // MARK: - Methods
    
    /// Calculer la quote part de valeur possédée
    /// - Parameter totalValue: Valeure totale du bien
    func ownedValue(from totalValue: Double) -> Double {
        return totalValue * fraction / 100.0
    }
}

extension Owner: CustomStringConvertible {
    public var description: String {
        "(\(name), \(fraction) %) "
    }
}

// MARK: - Un tableau de Owner

public typealias Owners = [Owner]

enum OwnersError: Error {
    case ownerDoesNotExist
    case noNewOwners
    case noOtherOwners
}

extension Owners {
    
    // MARK: - Computed Properties
    
    public var sumOfOwnedFractions: Double {
        self.sum(for: \.fraction)
    }
    public var percentageOk: Bool {
        sumOfOwnedFractions.isApproximatelyEqual(to: 100.0, absoluteTolerance: 0.0001)
    }
    public var isvalid: Bool {
        // si la liste est vide alors elle est valide
        guard !self.isEmpty else {
            return true
        }
        // tous les owners sont valides
        var validity = self.allSatisfy { $0.isValid }
        // somes des parts = 100%
        validity = validity && percentageOk
        return validity
    }
    
    // MARK: - Methods
    
    public subscript(ownerName: String) -> Owner? {
        self.first(where: { ownerName == $0.name })
    }
    
    public static func == (lhs: Owners, rhs: Owners) -> Bool {
        for owner in lhs {
            guard let found = rhs[owner.name] else { return false }
            if !found.fraction.isApproximatelyEqual(to: owner.fraction,
                                                    absoluteTolerance: 0.0001) { return false }
        }
        for owner in rhs {
            guard let found = lhs[owner.name] else { return false }
            if !found.fraction.isApproximatelyEqual(to: owner.fraction,
                                                    absoluteTolerance: 0.0001) { return false }
        }
        return true
    }
    
    public func contains(ownerName: String) -> Bool {
        self[ownerName] != nil
    }
    
    public func ownerIdx(ownerName: String) -> Int? {
        self.firstIndex(where: { ownerName == $0.name })
    }
    
    /// Transérer la propriété d'un Owner vers plusieurs autres par parts égales
    /// - Parameters:
    ///   - thisOwner: celui qui sort
    ///   - theseNewOwners: ceux qui le remplacent par parts égales
    /// - Throws:
    ///  - `ownerDoesNotExist`: le propriétaire recherché n'est pas dans la liste des propriétaire
    ///  - `noNewOwners`: la liste des nouveaux propriétaires est vide
    public mutating func replace(thisOwner           : String,
                                 with theseNewOwners : [String]) throws {
        guard theseNewOwners.count != 0 else { throw OwnersError.noNewOwners }
        
        if let ownerIdx = self.ownerIdx(ownerName: thisOwner) {
            // part à redistribuer
            let ownerShare = self[ownerIdx].fraction
            // retirer l'ancien propriétaire
            self.remove(at: ownerIdx)
            // ajouter les nouveaux propriétaires par parts égales
            theseNewOwners.forEach { newOwner in
                self.append(Owner(name: newOwner, fraction: ownerShare / theseNewOwners.count.double()))
            }
            // Factoriser les parts des owners si nécessaire
            groupShares()
            
        } else {
            throw OwnersError.ownerDoesNotExist
        }
    }
    
    public mutating func redistributeShare(of owner: String) throws {
        if let ownerIdx = self.ownerIdx(ownerName: owner) {
            guard self.count > 1 else { throw OwnersError.noOtherOwners }
            // part à redistribuer
            let ownerShare = self[ownerIdx].fraction
            // retirer l'ancien propriétaire
            self.remove(at: ownerIdx)
            for idx in self.indices where self[idx].name != owner {
                self[idx].fraction += ownerShare / (self.count).double()
            }
            
        } else {
            throw OwnersError.ownerDoesNotExist
        }
    }
    
    /// Factoriser les parts des owners si nécessaire
    public mutating func groupShares() {
        // identifer les owners et compter les occurences de chaque owner dans le tableau
        let dicOfOwnersNames = self.reduce(into: [:]) { counts, owner in
            counts[owner.name, default: 0] += 1
        }
        var newTable = [Owner]()
        // factoriser toutes les parts détenues par un même owner
        for (ownerName, _) in dicOfOwnersNames {
            // calculer le cumul des parts détenues par ownerName
            let totalShare = self.reduce(0, { result, owner in
                result + (owner.name == ownerName ? owner.fraction : 0)
            })
            newTable.append(Owner(name: ownerName, fraction: totalShare))
        }
        // retirer les owners ayant une part nulle
        self = newTable.filter { $0.fraction != 0 }
    }
    
}
