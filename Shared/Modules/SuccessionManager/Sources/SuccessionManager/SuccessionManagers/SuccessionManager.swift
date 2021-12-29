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
    
    // MARK: - Nested Types
    
    public struct SuccessionsSynthesis: CustomStringConvertible {
        /// Les successions légales / assurances vie survenues dans l'année
        public var successions      : [Succession] = []
        /// Somme des revenus bruts (en cash) des successions légales / assurances vie survenues dans l'année, par personne
        public var revenuesAdults   = NamedValueArray()
        public var revenuesChildren = NamedValueArray()
        /// Somme des taxes sur les successions légales / assurances vie survenues dans l'année, par personne
        public var taxesAdults      = NamedValueArray()
        public var taxesChildren    = NamedValueArray()
        
        public var description: String {
            """

            Successions:
            \(String(describing: successions).withPrefixedSplittedLines("  "))
                Héritage brut reçu par les adults:
                  \(String(describing: revenuesAdults).withPrefixedSplittedLines("  "))
                Héritage brut reçu par les enfants:
                  \(String(describing: revenuesChildren).withPrefixedSplittedLines("  "))
                Droits de succession à payer par les adults:
                  \(String(describing: taxesAdults).withPrefixedSplittedLines("  "))
                Droits de succession à payer par les enfants:
                  \(String(describing: taxesChildren).withPrefixedSplittedLines("  "))

            """
        }
    }
    
    // MARK: - Properties
    
    var family              : FamilyProviderP
    var patrimoine          : Patrimoin
    var year                : Int
    private var fiscalModel : Fiscal.Model
    private var run         : Int
    
    /// délégués
    private var legalSuccessionManager : LegalSuccessionManager
    var lifeInsuranceSuccessionManager : LifeInsuranceSuccessionManager
    var ownershipManager               : OwnershipManager
    
    /// résultats des calculs des successions légales et assurances vie survenues dans l'année
    public var legal         = SuccessionsSynthesis()
    public var lifeInsurance = SuccessionsSynthesis()
    public var creanceDeRestituationDico : CreanceDeRestituationDico {
        lifeInsuranceSuccessionManager.creanceDeRestituationDico
    }
    
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
    ///      * Modifier les clauses d'AV dont le défunt est un des donataires
    ///
    ///    * 3 - Cummuler les taxes de successions/transmissions et le Cash reçu de l'année.
    ///
    /// - Parameters:
    ///   - previousSuccession: succession précédente pour les assuarnces vies
    public mutating func manageSuccessions(previousSuccession : Succession?,
                                           verbose            : Bool = false) {
        // tout remettre à 0 avant chaque calcul
        legal         = SuccessionsSynthesis()
        lifeInsurance = SuccessionsSynthesis()
        
        /// (1) identification des personnes décédées dans l'année (ordonnés par âge décroissant)
        let adultDecedentsNames = family.deceasedAdults(during: year)
        
        
        /// (2) pour chaque défunt
        adultDecedentsNames.forEach { decedentName in
            manageSuccession(of                 : decedentName,
                             isFirstDecedent    : decedentName == adultDecedentsNames.first,
                             nbOfDecedents      : adultDecedentsNames.count,
                             previousSuccession : previousSuccession,
                             verbose            : verbose)
        }
        
        /// (3) Cummuler les droits de successions/transmissions de l'année par personne et le Cash reçu
        computeCashAndTaxesPerPerson(legalSuccessions   : legal.successions,
                                     lifeInsSuccessions : lifeInsurance.successions,
                                     verbose            : verbose)
        
        if verbose && adultDecedentsNames.isNotEmpty {
            print(String(describing: self))
        }
    }
    
    /// Gérer la succession de `decedentName`.
    ///
    /// - Note:
    ///    1. Modifier les clauses d'AV dont le défunt est un des donataires
    ///    2. Calculer les successions/transmissions et les droits associés.
    ///    3. Modifier une clause d'AV pour permettre le payement des droits des enfants par les enfants
    ///    4. Transférer les biens du défunt vers ses héritiers.
    ///    5. Vérifier que les actifs sont toujours valides après tous ces changements
    ///
    /// - Parameters:
    ///   - decedentName: Nom du défunt
    ///   - isFirstDecedent: true si le `decedentName` est le premier des défunts de l'année en cours
    ///   - nbOfDecedents: nombre de défunts de l'année
    ///   - previousSuccession: succession précédente pour les assuarnces vies
    mutating func manageSuccession(of decedentName    : String,
                                   isFirstDecedent    : Bool,
                                   nbOfDecedents      : Int,
                                   previousSuccession : Succession?,
                                   verbose            : Bool = false) {
        SimulationLogger.shared.log(run      : run,
                                    logTopic : .lifeEvent,
                                    message  : "Décès de \(decedentName) en \(year)")
        
        /// (1) Modifier les clauses d'AV dont le défunt est un des donataires
        let childrenAlive = family.childrenAliveName(atEndOf : year)
        try! ownershipManager.modifyClausesWhereDecedentIsFuturRecipient(
            decedentName : decedentName,
            childrenName : childrenAlive,
            withAssets   : &patrimoine.assets)
        
        /// (2) Calculer les successions et les droits de successions légales
        //    dernière succssion de l'année en cours ou, à défaut, des années précédentes
        let lastLifeInsSuccession = lifeInsurance.successions.last ?? previousSuccession
        let legalSuccession =
            legalSuccessionManager.succession(of                 : decedentName,
                                              isFirstDecedent    : isFirstDecedent,
                                              with               : patrimoine,
                                              previousSuccession : lastLifeInsSuccession,
                                              verbose            : verbose)
        
        /// (2) Calculer les transmissions et les droits de transmission assurances vies
        /// sans exercer de clause à option
        var spouseName: String?
        if let _spouseName = family.spouseNameOf(decedentName),
           isFirstDecedent,
           // pour le conjoint, il peut décéder la même année => il faut vérifier qu'il est vivant à la fin de l'année précédente
           family.member(withName: _spouseName)!.isAlive(atEndOf: year - 1) {
            spouseName = _spouseName
        }
        var lifeInsSuccession =
            lifeInsuranceSuccessionManager.succession(
                of           : decedentName,
                with         : patrimoine,
                spouseName   : spouseName,
                childrenName : childrenAlive,
                verbose      : verbose)
        
        /// (3) Modifier une clause d'AV pour permettre le payement des droits des enfants par les enfants
        // au premier décès parmis les adultes:
        // s'assurer que les enfants peuvent payer les droits de succession
        if isFirstDecedent && family.nbOfAdults == 2 &&
            (family.nbOfAdultAlive(atEndOf: year) == 1 ||
                family.nbOfAdultAlive(atEndOf: year) == 0 && nbOfDecedents == 2) {
            try! makeSureChildrenCanPaySuccessionTaxes(
                of                : decedentName,
                legalSuccession   : legalSuccession,
                lifeInsSuccession : &lifeInsSuccession,
                verbose           : verbose)
        }
        
        legal.successions.append(legalSuccession)
        lifeInsurance.successions.append(lifeInsSuccession)
        
        /// (4) Transférer les biens d'un défunt vers ses héritiers
        ownershipManager.transferOwnershipOf(
            assets          : &patrimoine.assets,
            liabilities     : &patrimoine.liabilities,
            of              : decedentName,
            isFirstDecedent : isFirstDecedent)
        
        /// (5) Vérifier que les actifs sont toujours valides après tous ces changements
        patrimoine.assets.checkValidity()
    }
    
    /// Cumule les cash reçus, droits de succession  aux taxes de transmission de l'année de succession.
    ///
    /// On traite séparément les PARENTS et par les ENFANTS.
    ///
    /// On traite séparément les successions LEGALES et transmission d'ASSURANCE VIE.
    ///
    mutating func computeCashAndTaxesPerPerson(legalSuccessions   : [Succession],
                                               lifeInsSuccessions : [Succession],
                                               verbose            : Bool = false) {
        family.members.items.sorted(by:>).forEach { member in
            /// successions légales
            var taxe: Double = 0
            var cash: Double = 0
            let mamberName = member.displayName
            legalSuccessions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.successorName == mamberName {
                        taxe += inheritance.tax
                        cash += inheritance.received
                    }
                }
            }
            if member is Adult {
                legal.taxesAdults
                    .append(NamedValue(name  : mamberName,
                                       value : taxe))
                legal.revenuesAdults
                    .append(NamedValue(name  : mamberName,
                                       value : cash))
            } else {
                legal.taxesChildren
                    .append(NamedValue(name  : mamberName,
                                       value : taxe))
                legal.revenuesChildren
                    .append(NamedValue(name  : mamberName,
                                       value : cash))
            }
            
            /// succession des assurances vies
            taxe = 0
            cash = 0
            lifeInsSuccessions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.successorName == mamberName {
                        taxe += inheritance.tax
                        cash += inheritance.received
                    }
                }
            }
            if member is Adult {
                lifeInsurance.taxesAdults
                    .append(NamedValue(name  : mamberName,
                                       value : taxe))
                lifeInsurance.revenuesAdults
                    .append(NamedValue(name  : mamberName,
                                       value : cash))
            } else {
                lifeInsurance.taxesChildren
                    .append(NamedValue(name  : mamberName,
                                       value : taxe))
                lifeInsurance.revenuesChildren
                    .append(NamedValue(name  : mamberName,
                                       value : cash))
            }
        }
    }
}

extension SuccessionManager: CustomStringConvertible {
    public var description: String {
        """
        Successions Légales:
        \(String(describing: legal).withPrefixedSplittedLines("  "))

        Successions Assurances Vies:
        \(String(describing: lifeInsurance).withPrefixedSplittedLines("  "))

        """
    }
}
