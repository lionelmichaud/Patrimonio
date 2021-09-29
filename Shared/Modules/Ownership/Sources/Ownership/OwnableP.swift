//
//  Ownable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import NamedValue

// MARK: Protocol d'Item qui peut être Possédé, Valuable et Nameable

public protocol OwnableP: NameableValuableP {
    var ownership: Ownership { get set }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationContext : EvaluationContext) -> Double
    
    /// Calcule une fraction `evaluatedFraction` de la valeur du bien
    /// détenu en tout ou partie par la personne nommée `ownerName` et
    /// uniquement si la nature du bien répond au critère `withOwnershipNature`
    /// - Note:
    ///     - si la nature du bien ne répond PAS au critère `withOwnershipNature`
    ///       alors retourne 0.0
    ///     - si `ownerName` n'a AUCUNE  part de propriété dans le bien, retorune 0.0
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - withOwnershipNature: nature de propriété sélectionnée
    ///   - evaluatedFraction: méthode d'évaluation sélectionnée
    /// - Returns: fraction `evaluatedFraction` de la valeur du bien
    func ownedValue(by ownerName        : String,
                    atEndOf year        : Int,
                    withOwnershipNature : OwnershipNature,
                    evaluatedFraction   : EvaluatedFraction) -> Double

    /// Rend un dictionnaire [Owner, Valeur possédée] en appelalnt la méthode ownedValue()
    /// - Parameters:
    ///   - year: date d'évaluation
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
    /// - Returns: dictionnaire [Owner, Valeur possédée]
    func ownedValues(atEndOf year     : Int,
                     evaluationContext : EvaluationContext) -> [String : Double]
    
    func ownedValues(ofValue totalValue : Double,
                     atEndOf year       : Int,
                     evaluationContext  : EvaluationContext) -> [String : Double]
    
    /// True si une des personnes listées perçoit des revenus de ce bien.
    /// Cad si elle est une des UF ou une des PP
    /// - Parameter names: liste de noms de membres de la famille
    func providesRevenue(to names: [String]) -> Bool
    
    /// True si une des personnes listées fait partie des PP de ce bien.
    /// - Parameter names: liste de noms de membres de la famille
    func hasAFullOwner(in names: [String]) -> Bool
    
    /// True si le bien fait partie du patrimoine d'une des personnes listées.
    /// Cad si elle est une des UF ou une des PP ou une des NP
    /// - Parameter names: liste de noms de membres de la famille
    func isPartOfPatrimoine(of names: [String]) -> Bool

    /// True si le bien satisfait au critère `criteria` pour la personne nommée `name`
    /// - Parameters:
    ///   - criteria: nature de propriété recherchée
    ///   - name: le nom du de personne recherchée parmi les propriétaires du bien
    /// - Returns: True si le bien satisfait au critère `criteria` pour la personne nommée `name`
    func satisfies(criteria : OwnershipNature,
                   for name : String) -> Bool
}

public extension OwnableP {
    // implémentation par défaut
    func ownedValue(by ownerName      : String,
                    atEndOf year      : Int,
                    evaluationContext : EvaluationContext) -> Double {
        // cas particuliers
        switch evaluationContext {
            case .legalSuccession:
                // cas particulier d'une succession:
                //   le défunt est-il usufruitier ?
                if ownership.isDismembered && ownership.hasAnUsufructOwner(named: ownerName) {
                    // si oui alors l'usufruit rejoint la nu-propriété sans droit de succession
                    // l'usufruit n'est donc pas intégré à la masse successorale du défunt
                    return 0
                }
                
            case .lifeInsuranceSuccession:
                // cas particulier d'une succession:
                // on recherche uniquement les assurances vies
                return 0
                
            case .ifi, .isf, .patrimoine:
                ()
        }
        
        // cas général
        // prendre la valeur totale du bien sans aucune décote
        let evaluatedValue = value(atEndOf: year)
        // prendre la fraction possédée par ownerName
        let value = evaluatedValue == 0 ? 0 : ownership.ownedValue(by                : ownerName,
                                                                   ofValue           : evaluatedValue,
                                                                   atEndOf           : year,
                                                                   evaluationContext : evaluationContext)
        return value
    }
    
    // implémentation par défaut
    func ownedValue(by ownerName        : String,
                    atEndOf year        : Int,
                    withOwnershipNature : OwnershipNature,
                    evaluatedFraction   : EvaluatedFraction) -> Double {
        guard satisfies(criteria: withOwnershipNature, for: ownerName) else {
            return 0
        }
        switch evaluatedFraction {

            case .totalValue:
                return value(atEndOf: year).rounded()

            case .ownedValue:
                return ownedValue(by               : ownerName,
                                  atEndOf          : year,
                                  evaluationContext: .patrimoine).rounded()
        }
    }

    func ownedValues(atEndOf year      : Int,
                     evaluationContext : EvaluationContext) -> [String : Double] {
        var dico: [String : Double] = [:]
        if ownership.isDismembered {
            for owner in ownership.bareOwners {
                dico[owner.name] = ownedValue(by                : owner.name,
                                              atEndOf           : year,
                                              evaluationContext : evaluationContext)
            }
            for owner in ownership.usufructOwners {
                dico[owner.name] = ownedValue(by                : owner.name,
                                              atEndOf           : year,
                                              evaluationContext : evaluationContext)
            }
            
        } else {
            // valeur en pleine propriété
            for owner in ownership.fullOwners {
                dico[owner.name] = ownedValue(by                : owner.name,
                                              atEndOf           : year,
                                              evaluationContext : evaluationContext)
            }
        }
        return dico
    }
    
    func ownedValues(ofValue totalValue : Double,
                     atEndOf year       : Int,
                     evaluationContext  : EvaluationContext) -> [String : Double] {
        var dico: [String : Double] = [:]
        if ownership.isDismembered {
            for owner in ownership.bareOwners {
                dico[owner.name] = ownership.ownedValue(by                : owner.name,
                                                        ofValue           : totalValue,
                                                        atEndOf           : year,
                                                        evaluationContext : evaluationContext)
            }
            for owner in ownership.usufructOwners {
                dico[owner.name] = ownership.ownedValue(by                : owner.name,
                                                        ofValue           : totalValue,
                                                        atEndOf           : year,
                                                        evaluationContext : evaluationContext)
            }
            
        } else {
            // valeur en pleine propriété
            for owner in ownership.fullOwners {
                dico[owner.name] = ownership.ownedValue(by                : owner.name,
                                                        ofValue           : totalValue,
                                                        atEndOf           : year,
                                                        evaluationContext : evaluationContext)
            }
        }
        return dico
    }
    
    func providesRevenue(to names: [String]) -> Bool {
        names.first(where: {
            ownership.providesRevenue(to: $0)
        }) != nil
    }
    
    func hasAFullOwner(in names: [String]) -> Bool {
        names.first(where: {
            ownership.hasAFullOwner(named: $0)
        }) != nil
    }
    
    func isPartOfPatrimoine(of names: [String]) -> Bool {
        names.first(where: {
            ownership.hasAFullOwner(named: $0) || ownership.hasAnUsufructOwner(named: $0) || ownership.hasABareOwner(named: $0)
        }) != nil
    }

    /// True si le bien satisfait au critère `criteria` pour la personne nommée `ownerName`
    /// - Parameters:
    ///   - ownerName: le nom du de personne dont on calcule le bilan
    ///   - criteria: nature de propriété sélectionnée
    /// - Returns: True si le bien satisfait au critère `criteria` pour la personne nommée `ownerName`
    func satisfies(criteria      : OwnershipNature,
                   for ownerName : String) -> Bool {
        switch criteria {

            case .generatesRevenue:
                return providesRevenue(to: [ownerName])

            case .sellable:
                return hasAFullOwner(in: [ownerName])

            case .all:
                return isPartOfPatrimoine(of: [ownerName])
        }
    }
}

extension Array where Element: OwnableP {
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    public func sumOfOwnedValues (by ownerName      : String,
                                  atEndOf year      : Int,
                                  evaluationContext : EvaluationContext) -> Double {
        return reduce(.zero, {result, element in
            return result + element.ownedValue(by                : ownerName,
                                               atEndOf           : year,
                                               evaluationContext : evaluationContext)
        })
    }
}
