//
//  SuccessionManager.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/09/2021.
//

import Foundation
import os
import FiscalModel
import Succession
import NamedValue
import Ownership
import PatrimoineModel
import PersonModel
import FamilyModel
import SimulationLogger

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SuccessionManager")

public struct SuccessionManager {
    
    // MARK: - Properties
    
    private var family      : FamilyProviderP
    private var patrimoine  : Patrimoin
    private var fiscalModel : Fiscal.Model
    private var year        : Int
    private var run         : Int
    
    private var legalSuccessionManager         : LegalSuccessionManager
    private let lifeInsuranceSuccessionManager : LifeInsuranceSuccessionManager
    private var ownershipManager               : OwnershipManager
    
    /// Les successions légales et assurances vie survenues dans l'année
    public var legalSuccessions   : [Succession] = []
    public var lifeInsSuccessions : [Succession] = []
    
    /// Taxes sur les successions légales et assurances vie survenues dans l'année
    public var legalSuccessionsTaxesAdults     = NamedValueArray()
    public var legalSuccessionsTaxesChildren   = NamedValueArray()
    public var lifeInsSuccessionsTaxesAdults   = NamedValueArray()
    public var lifeInsSuccessionsTaxesChildren = NamedValueArray()
    
    // MARK: - Initializers
    
    /// - Parameters:
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine de la famille
    ///   - fiscalModel: model fiscal à utiliser
    ///   - year: année des décès
    ///   - run: numéro du run en cours de calcul
    public init(with patrimoine   : Patrimoin,
                using fiscalModel : Fiscal.Model,
                atEndOf year      : Int,
                familyProvider    : FamilyProviderP,
                run               : Int) {
        self.patrimoine       = patrimoine
        self.family           = familyProvider
        self.fiscalModel      = fiscalModel
        self.year             = year
        self.run              = run
        self.legalSuccessionManager =
            LegalSuccessionManager(using          : fiscalModel,
                                   familyProvider : familyProvider,
                                   atEndOf        : year)
        self.lifeInsuranceSuccessionManager =
            LifeInsuranceSuccessionManager(using          : fiscalModel,
                                           familyProvider : familyProvider,
                                           atEndOf        : year)
        self.ownershipManager =
            OwnershipManager(of      : family,
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
    ///
    public mutating func manageSuccession(verbose: Bool = false) {
        // tout remettre à 0 avant chaque calcul
        legalSuccessions                = []
        legalSuccessionsTaxesAdults     = []
        legalSuccessionsTaxesChildren   = []
        lifeInsSuccessions              = []
        lifeInsSuccessionsTaxesAdults   = []
        lifeInsSuccessionsTaxesChildren = []
        
        // (1) identification des personnes décédées dans l'année
        let adultDecedentsNames = family.deceasedAdults(during: year)
        
        guard adultDecedentsNames.isNotEmpty else { return }
        
        // (2) pour chaque défunt
        adultDecedentsNames.forEach { adultDecedentName in
            SimulationLogger.shared.log(run      : run,
                                        logTopic : .lifeEvent,
                                        message  : "Décès de \(adultDecedentName) en \(year)")
            
            // calculer les successions et les droits de successions légales
            // sans exercer de clause à option
            let legalSuccession =
                legalSuccessionManager.legalSuccession(of      : adultDecedentName,
                                                       with    : patrimoine,
                                                       verbose : verbose)
            
            // calculer les transmissions et les droits de transmission assurances vies
            // sans exercer de clause à option
            var spouseName: String?
            if let _spouseName = family.spouseNameOf(adultDecedentName) {
                if family.member(withName: _spouseName)!.isAlive(atEndOf: year) {
                    spouseName = _spouseName
                }
            }
            let childrenAlive = family.childrenAliveName(atEndOf : year)
            var lifeInsSuccession =
                lifeInsuranceSuccessionManager.lifeInsuranceSuccession(
                    of           : adultDecedentName,
                    with         : patrimoine,
                    spouseName   : spouseName,
                    childrenName : childrenAlive,
                    verbose      : verbose)
            
            // au premier décès parmis les adultes:
            // s'assurer que les enfants peuvent payer les droits de succession
            if adultDecedentName == adultDecedentsNames.first &&
                family.nbOfAdults == 2 &&
                (family.nbOfAdultAlive(atEndOf: year) == 1 ||
                    family.nbOfAdultAlive(atEndOf: year) == 0 && adultDecedentsNames.count == 2) {
                makeSureChildrenCanPaySuccessionTaxes(of                : adultDecedentName,
                                                      legalSuccession   : legalSuccession,
                                                      lifeInsSuccession : &lifeInsSuccession,
                                                      verbose           : verbose)
            }
            
            legalSuccessions.append(legalSuccession)
            lifeInsSuccessions.append(lifeInsSuccession)
            
            // transférer les biens d'un défunt vers ses héritiers
            ownershipManager.transferOwnershipOf(assets      : &patrimoine.assets,
                                                 liabilities : &patrimoine.liabilities,
                                                 of          : adultDecedentName)
            
            // prélèvement à la source des taxes de trnansmission sur les capitaux dècès d'AV
            lifeInsuranceSuccessionManager.removeTransmissionTaxes(of           : adultDecedentName,
                                                             with         : patrimoine,
                                                             spouseName   : spouseName,
                                                             childrenName : childrenAlive,
                                                             verbose      : verbose)
        }
        
        // (3) Cummuler les droits de successions/transmissions de l'année par personne
        computeSuccessionsTaxesPerPerson(legalSuccessions   : legalSuccessions,
                                         lifeInsSuccessions : lifeInsSuccessions,
                                         verbose            : verbose)
        
        if verbose {
            print(String(describing: self))
        }
    }
    
    fileprivate func makeSureChildrenCanPaySuccessionTaxes
    (of decedentName   : String,
     legalSuccession   : Succession,
     lifeInsSuccession : inout Succession,
     verbose           : Bool = false) {
        
        // calculer les taxes dûes par les enfants au premier décès
        let childrenInheritancesTaxe =
            totalChildrenInheritanceTaxe(legalSuccession   : legalSuccession,
                                         lifeInsSuccession : lifeInsSuccession,
                                         verbose           : verbose)
        
        // si nécessaire et si possible: l'adulte survivant exerce une option de clause d'AV
        // pour permettre le payement des droits de succession des enfants par les enfants
        let adultSurvivorName = family.adultsName.first { $0 != decedentName}!
        print("> Adulte décédé   : \(decedentName)")
        print("> Adulte survivant: \(adultSurvivorName)")
        print("> Droits de succession des enfants:\n \(childrenInheritancesTaxe)\n Somme = \(childrenInheritancesTaxe.values.sum().k€String)")
        try! ownershipManager.modifyLifeInsuranceClauseIfNecessaryAndPossible(
            of              : decedentName,
            conjointName    : adultSurvivorName,
            withAssets      : &patrimoine.assets,
            withLiabilities : patrimoine.liabilities,
            toPayFor        : childrenInheritancesTaxe)
        
        // recalculer les transmissions et les droits de transmission assurances vies
        // après avoir éventuellement exercé une clause à option
        lifeInsSuccession =
            lifeInsuranceSuccessionManager.lifeInsuranceSuccession(
                of           : decedentName,
                with         : patrimoine,
                spouseName   : family.spouseNameOf(decedentName),
                childrenName : family.childrenAliveName(atEndOf : year),
                verbose      : verbose)
    }
    
    /// Calculer le total des taxes dûes par les enfants à partir des successions
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
    
    /// Ajoute les droits de succession  aux taxes de l'année de succession.
    ///
    /// On traite séparément les droits de succession dûs par les PARENTS et par les ENFANTS.
    ///
    /// On traite séparément les droits de succession LEGAUX et ASSURANCE VIE.
    ///
    mutating func computeSuccessionsTaxesPerPerson(legalSuccessions   : [Succession],
                                                   lifeInsSuccessions : [Succession],
                                                   verbose            : Bool = false) {
        family.members.items.forEach { member in
            /// successions légales
            var taxe: Double = 0
            legalSuccessions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.successorName == member.displayName {
                        taxe += inheritance.tax
                    }
                }
            }
            if member is Adult {
                legalSuccessionsTaxesAdults
                    .append(NamedValue(name  : member.displayName,
                                       value : taxe))
            } else {
                legalSuccessionsTaxesChildren
                    .append(NamedValue(name  : member.displayName,
                                       value : taxe))
            }
            /// succession des assurances vies
            taxe = 0
            lifeInsSuccessions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.successorName == member.displayName {
                        taxe += inheritance.tax
                    }
                }
            }
            if member is Adult {
                lifeInsSuccessionsTaxesAdults
                    .append(NamedValue(name  : member.displayName,
                                       value : taxe))
            } else {
                lifeInsSuccessionsTaxesChildren
                    .append(NamedValue(name  : member.displayName,
                                       value : taxe))
            }
        }
    }
}

extension SuccessionManager: CustomStringConvertible {
    public var description: String {
        """
        Successions Légales:
        \(String(describing: legalSuccessions).withPrefixedSplittedLines("  "))
            Droits de succession:
            \(String(describing: legalSuccessionsTaxesAdults + legalSuccessionsTaxesChildren).withPrefixedSplittedLines("  "))

        Successions Assurances Vies:
        \(String(describing: lifeInsSuccessions).withPrefixedSplittedLines("  "))
            Taxes de transmission:
            \(String(describing: lifeInsSuccessionsTaxesAdults + lifeInsSuccessionsTaxesChildren).withPrefixedSplittedLines("  "))
        """
    }
}
