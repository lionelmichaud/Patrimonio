//
//  Assets.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 09/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Statistics
import FiscalModel
import Files
import Ownership

// MARK: - Actifs de la famille

//typealias Assets = DictionaryOfItemArray<AssetsCategory,

public struct Assets {
    
    // MARK: - Type Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    public static func setSimulationMode(to thisMode : SimulationModeEnum) {
        // injecter l'inflation dans les Types d'investissements procurant
        // un rendement non réévalué de l'inflation chaque année
        SCPI.setSimulationMode(to: thisMode)
        PeriodicInvestement.setSimulationMode(to: thisMode)
        FreeInvestement.setSimulationMode(to: thisMode)
        // on suppose que les loyers des biens immobiliers physiques sont réévalués de l'inflation
        ()
        // on suppose que les valeurs de vente des biens immobiliers physiques et papier sont réévalués de l'inflation
        ()
        // on suppose que les salaires et les chiffres d'affaires sont réévalués de l'inflation
        ()
    }
    
    // MARK: - Properties
    
    public var periodicInvests : PeriodicInvestementArray
    public var freeInvests     : FreeInvestmentArray
    public var realEstates     : RealEstateArray
    public var scpis           : ScpiArray // SCPI hors de la SCI
    public var sci             : SCI
    public var allOwnableItems : [(ownable: OwnableP, category: AssetsCategory)] {
        var ownables = [(ownable: OwnableP, category: AssetsCategory)]()
        
        ownables =
            periodicInvests
            .items
            .sorted(by:<)
            .map { ($0, .periodicInvests) }
        ownables +=
            freeInvests
            .items
            .sorted(by:<)
            .map { ($0, .freeInvests) }
        ownables +=
            realEstates
            .items
            .sorted(by:<)
            .map { ($0, .realEstates) }
        ownables +=
            scpis
            .items
            .sorted(by:<)
            .map { ($0, .scpis) }
        ownables +=
            sci
            .scpis
            .items
            .sorted(by:<)
            .map { ($0, .sci) }
        return ownables
    }
    public var isModified      : Bool {
        return
            periodicInvests.isModified ||
            freeInvests.isModified ||
            realEstates.isModified ||
            scpis.isModified ||
            sci.isModified
    }
    // MARK: - Initializers
    
    /// Initialiser à vide
    public init() {
        self.periodicInvests = PeriodicInvestementArray()
        self.freeInvests     = FreeInvestmentArray()
        self.realEstates     = RealEstateArray()
        self.scpis           = ScpiArray()
        self.sci             = SCI()
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Note: personAgeProvider est utilisée pour injecter dans chaque actif un délégué personAgeProvider.ageOf
    ///         permettant de calculer les valeurs respectives des Usufruits et Nu-Propriétés
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    ///   - personAgeProvider: forunit l'age d'une personne à partir de son nom
    /// - Throws: en cas d'échec de lecture des données
    public init(fromFolder folder      : Folder,
                with personAgeProvider : PersonAgeProviderP?) throws {
        try self.periodicInvests = PeriodicInvestementArray(fromFolder: folder, with: personAgeProvider)
        try self.freeInvests     = FreeInvestmentArray(fromFolder: folder, with: personAgeProvider)
        try self.realEstates     = RealEstateArray(fromFolder: folder, with: personAgeProvider)
        try self.scpis           = ScpiArray(fromFolder: folder, with: personAgeProvider) // SCPI hors de la SCI
        try self.sci = SCI(fromFolder : folder,
                           name       : "LVLA",
                           note       : "Crée en 2019",
                           with       : personAgeProvider)
        
        // initialiser le vetcuer d'état de chaque FreeInvestement à la date courante
        initializeFreeInvestementCurrentValue()
    }
    
    // MARK: - Methods
    
    public func saveAsJSON(toFolder folder: Folder) throws {
        try periodicInvests.saveAsJSON(toFolder: folder)
        try freeInvests.saveAsJSON(toFolder: folder)
        try realEstates.saveAsJSON(toFolder: folder)
        try scpis.saveAsJSON(toFolder: folder)
        try sci.saveAsJSON(toFolder: folder)
    }
    
    /// Réinitialiser les valeurs courantes des investissements libres
    /// - Warning:
    ///   - Doit être appelée après le chargement d'un objet FreeInvestement depuis le fichier JSON
    ///   - Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    public mutating func initializeFreeInvestementCurrentValue() {
        for idx in freeInvests.items.indices {
            freeInvests[idx].resetCurrentState()
        }
    }
    
    public func value(atEndOf year: Int) -> Double {
        var sum = realEstates.value(atEndOf: year)
        sum += scpis.value(atEndOf: year)
        sum += periodicInvests.value(atEndOf: year)
        sum += freeInvests.value(atEndOf: year)
        sum += sci.scpis.value(atEndOf: year)
        return sum
    }
    
    /// Calcule la somme des valeurs des actifs détenus par un personne nommée `ownerName`
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
    public func ownedValue(by ownerName     : String,
                           atEndOf year     : Int,
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
//        print("-> Owner recherché: \(ownerName)")
//        print("-> nature de propriété sélectionnée : \(withOwnershipNature.displayString)")
//        print("-> méthode d'évaluation sélectionnée: \(evaluatedFraction.displayString)")
        forEachOwnable { ownable in
            total += ownable.ownedValue(by                  : ownerName,
                                        atEndOf             : year,
                                        withOwnershipNature : withOwnershipNature,
                                        evaluatedFraction   : evaluatedFraction)
//            print("  -> Bien: \(ownable.name)")
//            print("    -> Valeur cumulée: \(total.k€String)")
        }
        return total
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    public func forEachOwnable(_ body: (OwnableP) throws -> Void) rethrows {
        try periodicInvests.items.forEach(body)
        try freeInvests.items.forEach(body)
        try realEstates.items.forEach(body)
        try scpis.items.forEach(body)
        try sci.forEachOwnable(body)
    }
    
    /// Calcule  la valeur nette taxable du patrimoine immobilier de la famille selon la méthode de calcul choisie
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
    ///   - year: année d'évaluation
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
    ///   - Returns: assiette nette fiscale calculée selon la méthode choisie
    public func realEstateValue(atEndOf year        : Int,
                                for fiscalHousehold : FiscalHouseholdSumatorP,
                                evaluationContext    : EvaluationContext) -> Double {
        switch evaluationContext {
            case .ifi, .isf :
                /// on prend la valeure IFI des biens immobiliers
                /// pour: le foyer fiscal
                return fiscalHousehold.sum(atEndOf: year) { name in
                    realEstates.ownedValue(by                : name,
                                           atEndOf           : year,
                                           evaluationContext : evaluationContext) +
                        scpis.ownedValue(by                : name,
                                         atEndOf           : year,
                                         evaluationContext : evaluationContext) +
                        sci.scpis.ownedValue(by                : name,
                                             atEndOf           : year,
                                             evaluationContext : evaluationContext)
                }
                
            case .legalSuccession, .patrimoine:
                /// on prend la valeure totale de tous les biens immobiliers
                return
                    realEstates.value(atEndOf: year) +
                    scpis.value(atEndOf: year) +
                    sci.scpis.value(atEndOf: year)
                
            case .lifeInsuranceSuccession:
                // on recherche uniquement les assurances vies
                return 0
        }
    }
}

extension Assets: CustomStringConvertible {
    public var description: String {
        """
        ACTIF:
        \(periodicInvests.description.withPrefixedSplittedLines("  "))
        \(freeInvests.description.withPrefixedSplittedLines("  "))
        \(realEstates.description.withPrefixedSplittedLines("  "))
        \(scpis.description.withPrefixedSplittedLines("  "))
        \(sci.description.withPrefixedSplittedLines("  "))
        """
    }
}
