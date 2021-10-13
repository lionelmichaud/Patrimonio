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
import Ownership
import PatrimoineModel
import PersonModel
import FamilyModel
import SimulationLogger

public struct SuccessionManager {
    
    // MARK: - Properties

    private var family     : Family
    private var patrimoine : Patrimoin
    private var model      : Model
    private var year       : Int
    private var run        : Int

    private var legalSuccessionManager         = LegalSuccessionManager()
    private let lifeInsuranceSuccessionManager = LifeInsuranceSuccessionManager()
    private var ownershipManager               : OwnershipManager

    /// Les successions légales et assurances vie survenues dans l'année
    public var legalSuccessions   : [Succession] = []
    public var lifeInsSuccessions : [Succession] = []

    /// Taxes sur les successions légales et assurances vie survenues dans l'année
    public var legalSuccessionsTaxes   = NamedValueArray()
    public var lifeInsSuccessionsTaxes = NamedValueArray()

    // MARK: - Initializers

    /// - Parameters:
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine de la famille
    ///   - model: model à utiliser (partie fiscale)
    ///   - year: année des décès
    ///   - run: numéro du run en cours de calcul
    public init(of family       : Family,
                with patrimoine : Patrimoin,
                using model     : Model,
                atEndOf year    : Int,
                run             : Int) {
        self.family           = family
        self.patrimoine       = patrimoine
        self.model            = model
        self.year             = year
        self.run              = run
        self.ownershipManager = OwnershipManager(of      : family,
                                                 atEndOf : year,
                                                 run     : run)
    }

    // MARK: - Methods

    /// Gérer les succession de l'année.
    ///
    /// - Note:
    ///    * 1 - Identifier tous les décès de l'année.
    ///
    ///    * 2 - Pour chaque défunt:
    ///      * Calculer les successions/transmissions et les droits associés.
    ///      * Modifier une clause d'AV pour permettre le payement des droits des enfants par les enfants
    ///      * Transférer les biens du défunt vers ses héritiers.
    ///
    ///    * 3 - Cummuler les droits de successions/transmissions de l'année.
    public mutating func manageSuccession() {
        legalSuccessions        = []
        legalSuccessionsTaxes   = []
        lifeInsSuccessions      = []
        lifeInsSuccessionsTaxes = []

        // (1) identification des personnes décédées dans l'année
        let decedents = family.deceasedAdults(during: year)
        
        guard decedents.isNotEmpty else { return }
        
        // (2) pour chaque défunt
        decedents.forEach { person in
            SimulationLogger.shared.log(run      : run,
                                        logTopic : .lifeEvent,
                                        message  : "Décès de \(person.displayName) en \(year)")
            guard let adultDecedent = person as? Adult else { return }
            
            // calculer les successions et les droits de successions légales
            // sans exercer de clause à option
            let legalSuccession =
                legalSuccessionManager.legalSuccession(in      : patrimoine,
                                                       of      : adultDecedent,
                                                       atEndOf : year,
                                                       using   : model)
            
            // calculer les transmissions et les droits de transmission assurances vies
            // sans exercer de clause à option
            var lifeInsSuccession =
                lifeInsuranceSuccessionManager.lifeInsuranceSuccession(in           : patrimoine,
                                                                       of           : adultDecedent,
                                                                       spouseName   : family.spouseOf(adultDecedent)?.displayName,
                                                                       childrenName : family.childrenAliveName(atEndOf : year),
                                                                       atEndOf      : year,
                                                                       using        : model)
            
            // au premier décès parmis les adultes:
            // s'assurer que les enfants peuvent payer les droits de succession
            if adultDecedent == decedents.first &&
                family.nbOfAdults == 2 &&
                (family.nbOfAdultAlive(atEndOf: year) == 1 ||
                    family.nbOfAdultAlive(atEndOf: year) == 0 && decedents.count == 2) {
                makeSureChildrenCanPaySuccessionTaxes(of                : adultDecedent,
                                                      legalSuccession   : legalSuccession,
                                                      lifeInsSuccession : &lifeInsSuccession)
            }
            
            legalSuccessions.append(legalSuccession)
            lifeInsSuccessions.append(lifeInsSuccession)

            // transférer les biens d'un défunt vers ses héritiers
            ownershipManager.transferOwnershipOf(assets      : &patrimoine.assets,
                                                 liabilities : &patrimoine.liabilities,
                                                 of          : adultDecedent)
        }
        
        // (3) Cummuler les droits de successions/transmissions de l'année
        updateSuccessionsTaxes()
    }

    fileprivate func makeSureChildrenCanPaySuccessionTaxes
    (of adultDecedent  : Adult,
     legalSuccession   : Succession,
     lifeInsSuccession : inout Succession) {
        // calculer les taxes dûes par les enfants au premier décès
        let childrenInheritancesTaxe =
        totalChildrenInheritanceTaxe(legalSuccession   : legalSuccession,
                                     lifeInsSuccession : lifeInsSuccession)

        // si nécessaire et si possible: l'adulte survivant exerce une option de clause d'AV
        // pour permettre le payement des droits de succession des enfants par les enfants
        let adultSurvivor = family.adults.first { $0.displayName != adultDecedent.displayName}!
        print("> Adulte décédé   : \(adultDecedent.displayName)")
        print("> Adulte survivant: \(adultSurvivor.displayName)")
        print("> Droits de succession des enfants:\n \(childrenInheritancesTaxe)\n Somme = \(childrenInheritancesTaxe.values.sum().k€String)")
        ownershipManager.modifyLifeInsuranceClauseIfNecessaryAndPossible(
            of              : adultDecedent,
            conjoint        : adultSurvivor,
            withAssets      : &patrimoine.assets,
            withLiabilities : patrimoine.liabilities,
            toPayFor        : childrenInheritancesTaxe)

        // recalculer les transmissions et les droits de transmission assurances vies
        // après avoir éventuellement exercé une clause à option
        lifeInsSuccession =
        lifeInsuranceSuccessionManager.lifeInsuranceSuccession(in           : patrimoine,
                                                               of           : adultDecedent,
                                                               spouseName   : family.spouseOf(adultDecedent)?.displayName,
                                                               childrenName : family.childrenAliveName(atEndOf : year),
                                                               atEndOf      : year,
                                                               using        : model)
    }
    
    /// Ajoute les droits de succession  aux taxes de l'année de succession.
    ///
    /// On traite séparément les droits de succession dûs par les parents et par les enfants.
    ///
    fileprivate mutating func updateSuccessionsTaxes() {
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
    /// - Returns: total des taxes dûes par les enfants
    fileprivate func totalChildrenInheritanceTaxe
    (legalSuccession   : Succession,
     lifeInsSuccession : Succession) -> NameValueDico {
        var childrenTaxes = NameValueDico()
        family.children.forEach { child in
            childrenTaxes[child.displayName] = 0
            /// successions légales
            /// succession des assurances vies
            [legalSuccession, lifeInsSuccession].forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.personName == child.displayName {
                        childrenTaxes[child.displayName]! += inheritance.tax
                    }
                }
            }
        }
        return childrenTaxes
    }
}
