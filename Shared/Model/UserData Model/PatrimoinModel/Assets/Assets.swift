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

struct Assets {

    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to thisMode : SimulationModeEnum) {
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
    
    var periodicInvests : PeriodicInvestementArray
    var freeInvests     : FreeInvestmentArray
    var realEstates     : RealEstateArray
    var scpis           : ScpiArray // SCPI hors de la SCI
    var sci             : SCI
    var allOwnableItems : [(ownable: Ownable, category: AssetsCategory)] {
        var ownables = [(ownable: Ownable, category: AssetsCategory)]()
        
        ownables = periodicInvests.items
            .sorted(by:<)
            .map { ($0, AssetsCategory.periodicInvests) }
        ownables += freeInvests.items
            .sorted(by:<)
            .map { ($0, AssetsCategory.freeInvests) }
        ownables += realEstates.items
            .sorted(by:<)
            .map { ($0, AssetsCategory.realEstates) }
        ownables += scpis.items
            .sorted(by:<)
            .map { ($0, AssetsCategory.scpis) }
        ownables += sci.scpis.items
            .sorted(by:<)
            .map { ($0, AssetsCategory.sci) }
        return ownables
    }
    var isModified      : Bool {
        return
            periodicInvests.isModified ||
            freeInvests.isModified ||
            realEstates.isModified ||
            scpis.isModified ||
            sci.isModified
    }
    // MARK: - Initializers
    
    /// Initialiser à vide
    init() {
        self.periodicInvests = PeriodicInvestementArray()
        self.freeInvests     = FreeInvestmentArray()
        self.realEstates     = RealEstateArray()
        self.scpis           = ScpiArray()
        self.sci             = SCI()
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    /// - Parameter personAgeProvider: famille à laquelle associer le patrimoine
    /// - Note: personAgeProvider est utilisée pour injecter dans chaque actif un délégué personAgeProvider.ageOf
    ///         permettant de calculer les valeurs respectives des Usufruits et Nu-Propriétés
    internal init(fromFolder folder      : Folder,
                  with personAgeProvider : PersonAgeProvider?) throws {
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

    func saveAsJSON(toFolder folder: Folder) throws {
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
    mutating func initializeFreeInvestementCurrentValue() {
        for idx in freeInvests.items.range {
            freeInvests[idx].resetCurrentState()
        }
    }
    
    func value(atEndOf year: Int) -> Double {
        var sum = realEstates.value(atEndOf: year)
        sum += scpis.value(atEndOf: year)
        sum += periodicInvests.value(atEndOf: year)
        sum += freeInvests.value(atEndOf: year)
        sum += sci.scpis.value(atEndOf: year)
        return sum
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    func forEachOwnable(_ body: (Ownable) throws -> Void) rethrows {
        try periodicInvests.items.forEach(body)
        try freeInvests.items.forEach(body)
        try realEstates.items.forEach(body)
        try scpis.items.forEach(body)
        try sci.forEachOwnable(body)
    }
    
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    mutating func transferOwnershipOf(decedentName       : String,
                                      chidrenNames       : [String]?,
                                      spouseName         : String?,
                                      spouseFiscalOption : InheritanceFiscalOption?,
                                      atEndOf year       : Int) {
        for idx in periodicInvests.items.range where periodicInvests.items[idx].value(atEndOf: year) > 0 {
            switch periodicInvests[idx].type {
                case .lifeInsurance(_, let clause):
                    // régles de transmission particulières pour l'Assurance Vie
                    // TODO: - ne transférer que ce qui n'est pas de l'assurance vie, sinon utiliser d'autres règles de transmission
                    try! periodicInvests[idx].ownership.transferLifeInsuranceOfDecedent(
                        of          : decedentName,
                        accordingTo : clause)
                    
                default:
                    try! periodicInvests[idx].ownership.transferOwnershipOf(
                        decedentName       : decedentName,
                        chidrenNames       : chidrenNames,
                        spouseName         : spouseName,
                        spouseFiscalOption : spouseFiscalOption)
            }
        }
        for idx in freeInvests.items.range where freeInvests.items[idx].value(atEndOf: year) > 0 {
            freeInvests[idx].initializeCurrentInterestsAfterTransmission(yearOfTransmission: year)
            switch freeInvests[idx].type {
                case .lifeInsurance(_, let clause):
                    // régles de transmission particulières pour l'Assurance Vie
                    // TODO: - ne transférer que ce qui n'est pas de l'assurance vie, sinon utiliser d'autres règles de transmission
                    try! freeInvests[idx].ownership.transferLifeInsuranceOfDecedent(
                        of          : decedentName,
                        accordingTo : clause)
                    
                default:
                    try! freeInvests[idx].ownership.transferOwnershipOf(
                        decedentName       : decedentName,
                        chidrenNames       : chidrenNames,
                        spouseName         : spouseName,
                        spouseFiscalOption : spouseFiscalOption)
            }
        }
        for idx in realEstates.items.range where realEstates.items[idx].value(atEndOf: year) > 0 {
            try! realEstates[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
        for idx in scpis.items.range where scpis.items[idx].value(atEndOf: year) > 0 {
            try! scpis.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
        sci.transferOwnershipOf(decedentName       : decedentName,
                                chidrenNames       : chidrenNames,
                                spouseName         : spouseName,
                                spouseFiscalOption : spouseFiscalOption,
                                atEndOf            : year)
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
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    ///   - Returns: assiette nette fiscale calculée selon la méthode choisie
    func realEstateValue(atEndOf year        : Int,
                         for fiscalHousehold : FiscalHouseholdSumator,
                         evaluationMethod    : EvaluationMethod) -> Double {
        switch evaluationMethod {
            case .ifi, .isf :
                /// on prend la valeure IFI des biens immobiliers
                /// pour: le foyer fiscal
                return fiscalHousehold.sum(atEndOf: year) { name in
                    realEstates.ownedValue(by               : name,
                                           atEndOf          : year,
                                           evaluationMethod : evaluationMethod) +
                        scpis.ownedValue(by               : name,
                                         atEndOf          : year,
                                         evaluationMethod : evaluationMethod) +
                        sci.scpis.ownedValue(by               : name,
                                             atEndOf          : year,
                                             evaluationMethod : evaluationMethod)
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
    var description: String {
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
