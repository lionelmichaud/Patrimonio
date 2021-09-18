//
//  SuccessionManager.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/09/2021.
//

import Foundation
import ModelEnvironment
import Succession
import NamedValue
import PatrimoineModel
import PersonModel
import FamilyModel
import SimulationLogger

public struct SuccessionManager {
    
    // MARK: - Properties
    
    private var legalSuccessionManager         = LegalSuccessionManager()
    private let lifeInsuranceSuccessionManager = LifeInsuranceSuccessionManager()
    private let ownershipManager               = OwnershipManager()

    /// Les successions légales et assurances vie survenues dans l'année
    public var legalSuccessions   : [Succession] = []
    public var lifeInsSuccessions : [Succession] = []

    /// Taxes sur les successions légales et assurances vie survenues dans l'année
    public var legalSuccessionsTaxes   = NamedValueArray()
    public var lifeInsSuccessionsTaxes = NamedValueArray()

    // MARK: - Initializers

    public init() {    }

    // MARK: - Methods

    /// Ajoute les droits de succession  aux taxes de l'année de succession.
    ///
    /// On traite séparément les droits de succession dûs par les parents et par les enfants.
    ///
    private mutating func updateSuccessionsTaxes(of family: Family) {
        family.members.items.forEach { member in
            /// successions légales
            var taxe: Double = 0
            legalSuccessions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.personName == member.displayName {
                        taxe += inheritance.tax
                    }
                }
            }
            legalSuccessionsTaxes
                .append((name  : member.displayName,
                         value : taxe))
            
            /// succession des assurances vies
            taxe = 0
            lifeInsSuccessions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.personName == member.displayName {
                        taxe += inheritance.tax
                    }
                }
            }
            lifeInsSuccessionsTaxes
                .append((name  : member.displayName,
                         value : taxe))
        }
    }
    
    /// Calculer le total des taxes dûes par les enfants
    /// - Parameter family: la famille
    /// - Returns: total des taxes dûes par les enfants
    private func totalChildrenInheritanceTaxe(of family: Family) -> Double {
        var taxe : Double = 0
        family.children.forEach { child in
            /// successions légales
            /// succession des assurances vies
            (legalSuccessions + lifeInsSuccessions).forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.personName == child.displayName {
                        taxe += inheritance.tax
                    }
                }
            }
        }
        return taxe
    }

    /// Gérer les succession de l'année.
    ///
    /// - Note:
    ///    * 1 - Identifier toutes les décès de l'année.
    ///
    ///    * 2 - Pour chaque défunt:
    ///      * Calculer les successions/transmissions et les droits associés.
    ///      * Modifier une clause d'AV pour permettre le payement des droits des enfants par les enfants
    ///      * Transférer les biens du défunt vers ses héritiers.
    ///
    ///    * 3 - Cummuler les droits de successions/transmissions de l'année.
    ///
    /// - Parameters:
    ///   - run: numéro du run en cours de calcul
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine de la famille
    public mutating func manageSuccession(run             : Int,
                                          of family       : Family,
                                          with patrimoine : Patrimoin,
                                          using model     : Model,
                                          atEndOf year    : Int) {
        legalSuccessions      = []
        lifeInsSuccessions    = []
        legalSuccessionsTaxes = []
        lifeInsSuccessions    = []

        // (1) identification des personnes décédées dans l'année
        let decedents = family.deceasedAdults(during: year)
        
        guard decedents.isNotEmpty else {
            return
        }
        
        // (2) pour chaque défunt
        decedents.forEach { person in
            SimulationLogger.shared.log(run      : run,
                                        logTopic : .lifeEvent,
                                        message  : "Décès de \(person.displayName) en \(year)")
            guard let adultDecedent = person as? Adult else {
                return
            }
            
            // calculer les successions et les droits de successions légales
            let legalSuccession =
                legalSuccessionManager.legalSuccession(in      : patrimoine,
                                                       of      : adultDecedent,
                                                       atEndOf : year,
                                                       using   : model)
            legalSuccessions.append(legalSuccession)
            
            // calculer les transmissions et les droits de transmission assurances vies
            let lifeInsSuccession =
                lifeInsuranceSuccessionManager.lifeInsuraceSuccession(in      : patrimoine,
                                                                      of      : adultDecedent,
                                                                      atEndOf : year,
                                                                      using   : model)
            lifeInsSuccessions.append(lifeInsSuccession)
            
            // au premier décès parmis les adultes:
            // s'assurer que les enfants peuvent payer les droits de succession
            if adultDecedent == decedents.first &&
                family.nbOfAdults == 2 &&
                (family.nbOfAdultAlive(atEndOf: year) == 1 ||
                    family.nbOfAdultAlive(atEndOf: year) == 0 && decedents.count == 2) {
                // calculer les taxes dûes par les enfants au premier décès
                let childrenInheritancesTaxe = totalChildrenInheritanceTaxe(of: family)

                // si nécessaire: modifier une clause d'AV de l'adulte survivant pour permettre
                // le payement des droits des enfants par les enfants
                let adultSurvivor = family.adults.first { $0.displayName != adultDecedent.displayName}!
                print(">Adulte décédé   : \(adultDecedent.displayName)")
                print(">Adulte survivant: \(adultSurvivor.displayName)")
                print(">Somme des droits de succession des enfants: \(childrenInheritancesTaxe.k€String)")
                ownershipManager.modifyLifeInsuranceClause(of       : adultDecedent,
                                                           conjoint : adultSurvivor,
                                                           in       : family,
                                                           with     : patrimoine,
                                                           toPayFor : childrenInheritancesTaxe,
                                                           atEndOf  : year)
            }
            
            // transférer les biens d'un défunt vers ses héritiers
            ownershipManager.transferOwnershipOf(assets      : &patrimoine.assets,
                                                 liabilities : &patrimoine.liabilities,
                                                 of          : adultDecedent,
                                                 atEndOf     : year)
        }
        
        // (3) Cummuler les droits de successions/transmissions de l'année
        updateSuccessionsTaxes(of: family)
    }
}
