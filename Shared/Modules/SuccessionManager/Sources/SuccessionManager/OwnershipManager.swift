//
//  OwnershipManager.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/04/2021.
//

import Foundation
import FiscalModel
import PersonModel
import FamilyModel
import PatrimoineModel
import AssetsModel
import Liabilities

struct OwnershipManager {
    
    // swiftlint:disable function_parameter_count
    
    /// Modifie une clause d'AV pour permettre le payement des droits de successions
    /// dûs par les enfants par ces derniers
    /// - Parameters:
    ///   - decedent: adulte décédé
    ///   - conjoint: l'adulte survivant au décès du premier adulte
    ///   - family: la famille
    ///   - patrimoine: son patrimoine
    ///   - taxes: les droits de succession à payer par les enfants
    ///   - year: l'année du décès
    func modifyLifeInsuranceClause
    (of decedent                 : Adult,
     conjoint                    : Adult,
     in family                   : Family,
     withAssets assets           : inout Assets,
     withLiabilities liabilities : Liabilities,
     toPayFor taxes              : Double,
     atEndOf year                : Int) {
        // cumuler les actifs nets dont les enfants sont les seuls PP après transmission
        let childrenSellableCapital =
            childrenSellableInheritedCapital(receivedFrom    : decedent,
                                             inFamily        : family,
                                             withAssets      : assets,
                                             withLiabilities : liabilities,
                                             atEndOf         : year)
        print(">Capital cessible détenu par les enfants après succession: \(childrenSellableCapital.k€String)")
        
        // calculer les capitaux manquants aux enfants pour pouvoir payer les droits de succession
        var missingCapital  = taxes - childrenSellableCapital
        print(">Capital manquant aux enfants pour payer les droits de succession: \(missingCapital.k€String)")

        guard missingCapital > 0.0 else {
            return
        }
        
        // prendre les valeurs à la fin de l'année précédente
        assets
            .freeInvests
            .items
            .sort {
                $0.ownedValue(by: decedent.displayName, atEndOf: year-1, evaluationContext: .patrimoine) >
                    $1.ownedValue(by: decedent.displayName, atEndOf: year-1, evaluationContext: .patrimoine)
            }
        //print(String(describing: patrimoine.assets.freeInvests.items))
        
        for idx in assets.freeInvests.items.range {
            let ownedValue =
                assets
                .freeInvests[idx]
                .ownedValue(by                : decedent.displayName,
                            atEndOf           : year-1,
                            evaluationContext : .patrimoine)
            print("Assurance: \(assets.freeInvests[idx].name)\n Valeur possédée en \(year-1): \(ownedValue.k€String)")
            guard ownedValue >= 0 else {
                break
            }
            // modifier la clause d'assurance vie
            
            // arrêter quand les capitaux des enfants sont suffisants pour payer
            missingCapital -= ownedValue
            if missingCapital <= 0 { break }
        }
    }
    
    private func childrenSellableInheritedCapital
    (receivedFrom decedent       : Adult,
     inFamily family             : Family,
     withAssets assets           : Assets,
     withLiabilities liabilities : Liabilities,
     atEndOf year                : Int) -> Double {
        // simuler les transmisssions pour calculer ce que les enfants
        // hériterons en PP sans modifier aucune clause d'AV
        var assetsCopy      = assets
        var liabilitiesCopy = liabilities
        transferOwnershipOf(assets      : &assetsCopy,
                            liabilities : &liabilitiesCopy,
                            of          : decedent,
                            atEndOf     : year)
        
        // cumuler les actifs nets dont les enfants sont les seuls PP après transmission
        return childrenNetSellableAssets(in              : family,
                                         withAssets      : assetsCopy,
                                         withLiabilities : liabilitiesCopy,
                                         atEndOf         : year)
    }
    
    /// Actif net vendable détenu par l'ensemble des enfants à la fin de l'année `year`
    /// pour à sa valeur patrimoniale.
    /// - Parameters:
    ///   - family: la famille
    ///   - assets: actifs de la famille
    ///   - liabilities: passifs de la famille
    ///   - year: année
    /// - Returns: actif net vendable détenu par l'ensemble des enfants à la fin de l'année
    private func childrenNetSellableAssets(in family                   : Family,
                                           withAssets assets           : Assets,
                                           withLiabilities liabilities : Liabilities,
                                           atEndOf year                : Int) -> Double {
        var total = 0.0
        // Attention: évaluer à la fin de l'année précédente (important pour les FreeInvestment)
        family.children.forEach { child in
            total += assets.ownedValue(by                  : child.displayName,
                                       atEndOf             : year - 1,
                                       withOwnershipNature : .sellable,
                                       evaluatedFraction   : .ownedValue) +
                liabilities.ownedValue(by                  : child.displayName,
                                       atEndOf             : year - 1,
                                       withOwnershipNature : .sellable,
                                       evaluatedFraction   : .ownedValue)
        }
        return total
    }
    
    /// Transférer la propriété d'un `patrimoine` d'un défunt `decedent` vers ses héritiers
    /// - Parameters:
    ///   - patrimoine: le patrimoine
    ///   - decedent: défunt
    ///   - year: année du décès
    func transferOwnershipOf(assets       : inout Assets,
                             liabilities  : inout Liabilities,
                             of decedent  : Adult,
                             atEndOf year : Int) {
        guard let family = Patrimoin.familyProvider else {
            fatalError("La famille n'est pas définie dans Patrimoin.transferOwnershipOf")
        }
        // rechercher un conjont survivant
        var spouseName         : String?
        var spouseFiscalOption : InheritanceFiscalOption?
        if let spouse = family.spouseOf(decedent) {
            if spouse.isAlive(atEndOf: year) {
                spouseName         = spouse.displayName
                spouseFiscalOption = spouse.fiscalOption
            }
        }
        // rechercher des enfants héritiers vivants
        let chidrenNames = family.childrenAliveName(atEndOf: year)
        
        // leur transférer la propriété de tous les biens détenus par le défunt
        // transférer les actifs
        transferOwnershipOf(assets             : &assets,
                            decedentName       : decedent.displayName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption,
                            atEndOf            : year)
        // transférer les passifs
        transferOwnershipOf(liabilities        : &liabilities,
                            decedentName       : decedent.displayName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption,
                            atEndOf            : year)
    }
    
    /// Transférer la propriété des `assets` d'un défunt `decedent` vers ses héritiers
    /// en fonction de l'option fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - assets: assets description
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    ///   - year: année du décès
    private func transferOwnershipOf(assets             : inout Assets,
                                     decedentName       : String,
                                     chidrenNames       : [String]?,
                                     spouseName         : String?,
                                     spouseFiscalOption : InheritanceFiscalOption?,
                                     atEndOf year       : Int) {
        for idx in assets.periodicInvests.items.range where assets.periodicInvests.items[idx].value(atEndOf: year) > 0 {
            switch assets.periodicInvests[idx].type {
                case .lifeInsurance(_, let clause):
                    // régles de transmission particulières pour l'Assurance Vie
                    // TODO: - ne transférer que ce qui n'est pas de l'assurance vie, sinon utiliser d'autres règles de transmission
                    try! assets.periodicInvests[idx].ownership.transferLifeInsuranceOfDecedent(
                        of          : decedentName,
                        accordingTo : clause)
                    
                default:
                    try! assets.periodicInvests[idx].ownership.transferOwnershipOf(
                        decedentName       : decedentName,
                        chidrenNames       : chidrenNames,
                        spouseName         : spouseName,
                        spouseFiscalOption : spouseFiscalOption)
            }
        }
        for idx in assets.freeInvests.items.range where assets.freeInvests.items[idx].value(atEndOf: year) > 0 {
            assets.freeInvests[idx].initializeCurrentInterestsAfterTransmission(yearOfTransmission: year)
            switch assets.freeInvests[idx].type {
                case .lifeInsurance(_, let clause):
                    // régles de transmission particulières pour l'Assurance Vie
                    // TODO: - ne transférer que ce qui n'est pas de l'assurance vie, sinon utiliser d'autres règles de transmission
                    try! assets.freeInvests[idx].ownership.transferLifeInsuranceOfDecedent(
                        of          : decedentName,
                        accordingTo : clause)
                    
                default:
                    try! assets.freeInvests[idx].ownership.transferOwnershipOf(
                        decedentName       : decedentName,
                        chidrenNames       : chidrenNames,
                        spouseName         : spouseName,
                        spouseFiscalOption : spouseFiscalOption)
            }
        }
        for idx in assets.realEstates.items.range where assets.realEstates.items[idx].value(atEndOf: year) > 0 {
            try! assets.realEstates[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
        for idx in assets.scpis.items.range where assets.scpis.items[idx].value(atEndOf: year) > 0 {
            try! assets.scpis.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
        assets.sci.transferOwnershipOf(decedentName       : decedentName,
                                       chidrenNames       : chidrenNames,
                                       spouseName         : spouseName,
                                       spouseFiscalOption : spouseFiscalOption,
                                       atEndOf            : year)
    }
    
    /// Transférer la propriété des `liabilities` d'un défunt `decedent` vers ses héritiers
    /// en fonction de l'option fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - liabilities: le passif
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    ///   - year: année du décès
    private func transferOwnershipOf(liabilities        : inout Liabilities,
                                     decedentName       : String,
                                     chidrenNames       : [String]?,
                                     spouseName         : String?,
                                     spouseFiscalOption : InheritanceFiscalOption?,
                                     atEndOf year       : Int) {
        // transférer les emprunts
        for idx in liabilities.loans.items.range where liabilities.loans.items[idx].value(atEndOf: year) > 0 {
            try! liabilities.loans.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
        // transférer les dettes
        for idx in liabilities.debts.items.range {
            try! liabilities.debts.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
    }
    // swiftlint:enable function_parameter_count
}
