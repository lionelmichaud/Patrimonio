//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 09/11/2021.
//

import Foundation
import AssetsLibrary
import Ownership
import PatrimoineModel
import AssetsModel
import FamilyModel
import Succession

extension SuccessionManager {
    
    /// S'assurer que les héritiers auront les moyens de payer les taxes et droits de succession
    /// Modifier au besoin une clause démembrée d'AV
    /// - Parameters:
    ///   - decedentName: Nom du défunr
    ///   - legalSuccession: Succession légales
    ///   - lifeInsSuccession: Transmissions d'AV
    mutating func makeSureChildrenCanPaySuccessionTaxes
    (of decedentName   : String,
     legalSuccession   : Succession,
     lifeInsSuccession : inout Succession,
     verbose           : Bool = false) throws {
        
        // calculer les taxes dûes par les enfants au premier décès
        let childrenInheritancesTaxe =
            totalChildrenInheritanceTaxe(legalSuccession   : legalSuccession,
                                         lifeInsSuccession : lifeInsSuccession,
                                         verbose           : verbose)
        
        // si nécessaire et si possible: l'adulte survivant exerce une option de clause d'AV
        // pour permettre le payement des droits de succession des enfants par les enfants
        let adultSurvivorName = family.adultsName.first { $0 != decedentName}!
        if verbose {
            print("> Adulte décédé   : \(decedentName)")
            print("> Adulte survivant: \(adultSurvivorName)")
            print("> Droits de succession des enfants:\n \(childrenInheritancesTaxe)\n Somme = \(childrenInheritancesTaxe.values.sum().k€String)")
        }
        try ownershipManager.modifyLifeInsuranceClauseIfNecessaryAndPossible(
            decedentName          : decedentName,
            conjointName          : adultSurvivorName,
            withAssets            : &patrimoine.assets,
            withLiabilities       : patrimoine.liabilities,
            toPayFor              : childrenInheritancesTaxe,
            capitauxDecesRecusNet : lifeInsuranceSuccessionManager.capitauxDeces,
            verbose               : verbose)
        
        // recalculer les transmissions et les droits de transmission assurances vies
        // après avoir éventuellement exercé une clause à option
        lifeInsSuccession =
            lifeInsuranceSuccessionManager.succession(
                of           : decedentName,
                with         : patrimoine,
                spouseName   : family.spouseNameOf(decedentName),
                childrenName : family.childrenAliveName(atEndOf : year),
                verbose      : verbose)
    }
    
    /// Calculer le total des taxes dûes par les enfants à partir des successions
    /// - Parameters:
    ///   - legalSuccession: Succession légales
    ///   - lifeInsSuccession: Transmissions d'AV
    /// - Returns: total des taxes dûes par les enfants [Nom; Taxe totale à payer]
    func totalChildrenInheritanceTaxe(legalSuccession   : Succession,
                                      lifeInsSuccession : Succession,
                                      verbose           : Bool = false) -> NameValueDico {
        
        var childrenTaxes = NameValueDico()
        family.childrenName.forEach { childName in
            childrenTaxes[childName] = 0
            /// successions légales
            /// succession des assurances vies
            [legalSuccession, lifeInsSuccession].forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.successorName == childName {
                        childrenTaxes[childName]! += inheritance.tax
                    }
                }
            }
        }
        return childrenTaxes
    }
}
