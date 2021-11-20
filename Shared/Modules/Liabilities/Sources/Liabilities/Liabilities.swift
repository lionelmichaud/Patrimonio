//
//  Liabilities.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import FiscalModel
import Files
import Ownership

public struct Liabilities {
    
    // MARK: - Properties
    
    public var debts : DebtArray
    public var loans : LoanArray
    public var allOwnableItems : [(ownable: OwnableP, category: LiabilitiesCategory)] {
        debts.items.sorted(by:<)
            .map { ($0, LiabilitiesCategory.debts) } +
            loans.items.sorted(by:<)
            .map { ($0, LiabilitiesCategory.loans) }
    }
    public var isModified      : Bool {
        return
            debts.persistenceState == .modified ||
            loans.persistenceState == .modified
    }
    
    // MARK: - Initializers
    
    /// Initialiser à vide
    public init() {
        self.debts = DebtArray()
        self.loans = LoanArray()
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Note: family est utilisée pour injecter dans chaque passif un délégué family.ageOf
    ///         permettant de calculer les valeurs respectives des Usufruits et Nu-Propriétés
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    ///   - personAgeProvider: forunit l'age d'une personne à partir de son nom
    /// - Throws: en cas d'échec de lecture des données
    public init(fromFolder folder      : Folder,
                with personAgeProvider : PersonAgeProviderP?) throws {
        try self.debts = DebtArray(fromFolder: folder, with: personAgeProvider)
        try self.loans = LoanArray(fromFolder: folder, with: personAgeProvider)
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le `bundle`
    /// - Note: Utilisé seulement pour les Tests
    /// - Note: family est utilisée pour injecter dans chaque passif un délégué family.ageOf
    ///         permettant de calculer les valeurs respectives des Usufruits et Nu-Propriétés
    /// - Parameters:
    ///   - bundle: le bundle dans lequel se trouve les fichiers JSON
    ///   - personAgeProvider: forunit l'age d'une personne à partir de son nom
    /// - Throws: en cas d'échec de lecture des données
    public init(fromBundle bundle      : Bundle,
                fileNamePrefix         : String = "",
                with personAgeProvider : PersonAgeProviderP?) {
        self.debts = DebtArray(fromBundle     : bundle,
                               fileNamePrefix : fileNamePrefix,
                               with           : personAgeProvider)
        self.loans = LoanArray(fromBundle     : bundle,
                               fileNamePrefix : fileNamePrefix,
                               with           : personAgeProvider)
    }

    // MARK: - Methods
    
    public func saveAsJSON(toFolder folder: Folder) throws {
        try debts.saveAsJSON(toFolder: folder)
        try loans.saveAsJSON(toFolder: folder)
    }
    
    public func value(atEndOf year: Int) -> Double {
        loans.items.sumOfValues(atEndOf: year) +
            debts.items.sumOfValues(atEndOf: year)
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    public func forEachOwnable(_ body: (OwnableP) throws -> Void) rethrows {
        try loans.items.forEach(body)
        try debts.items.forEach(body)
    }
    
    /// Calcule la somme des valeurs des passifs détenus par un personne nommée `ownerName`
    /// à la fin de l'année `year` selon la méthode `evaluationContext`: régle générale, règle de l'IFI, de l'ISF, de la succession...
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
    public func ownedValue(by ownerName      : String,
                           atEndOf year      : Int,
                           evaluationContext : EvaluationContext) -> Double {
        var total = 0.0
        forEachOwnable { ownable in
            total += ownable.ownedValue(by                : ownerName,
                                        atEndOf           : year,
                                        evaluationContext : evaluationContext)
        }
        return total
    }
    
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
    public func ownedValue(by ownerName        : String,
                           atEndOf year        : Int,
                           withOwnershipNature : OwnershipNature,
                           evaluatedFraction   : EvaluatedFraction) -> Double {
        var total = 0.0
        forEachOwnable { ownable in
            total += ownable.ownedValue(by                  : ownerName,
                                        atEndOf             : year,
                                        withOwnershipNature : withOwnershipNature,
                                        evaluatedFraction   : evaluatedFraction)
        }
        return total
    }
    
    /// Calcule  la valeur du patrimoine immobilier de la famille selon la méthode de calcul choisie
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - evaluationContext: méthode d'évalution des biens
    /// - Returns: assiette nette fiscale calculée selon la méthode choisie
    public func realEstateValue(atEndOf year        : Int,
                                for fiscalHousehold : FiscalHouseholdSumatorP,
                                evaluationContext   : EvaluationContext) -> Double {
        switch evaluationContext {
            case .ifi, .isf :
                /// on prend la valeure IFI des emprunts
                /// pour: le foyer fiscal
                return fiscalHousehold.sum(atEndOf: year) { name in
                    loans.ownedValue(by                : name,
                                     atEndOf           : year,
                                     evaluationContext : evaluationContext)
                }
                
            case .legalSuccession, .patrimoine:
                /// on prend la valeure totale de toutes les emprunts
                return loans.value(atEndOf: year)
                
            case .lifeInsuranceSuccession, .lifeInsuranceTransmission:
                return 0
        }
    }
    
    public func valueOfDebts(atEndOf year: Int) -> Double {
        debts.value(atEndOf: year)
    }
    
    public func valueOfLoans(atEndOf year: Int) -> Double {
        loans.value(atEndOf: year)
    }
}

extension Liabilities: CustomStringConvertible {
    public var description: String {
        """
        PASSIF:
        \(debts.description.withPrefixedSplittedLines("  "))
        \(loans.description.withPrefixedSplittedLines("  "))
        """
    }
}
