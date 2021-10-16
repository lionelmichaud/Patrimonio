//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 12/10/2021.
//

import Foundation
import FiscalModel
import PersonModel
import PatrimoineModel
import AssetsModel
import Liabilities

extension OwnershipManager {

    /// Transférer la propriété d'un `patrimoine` d'un défunt `decedent` vers ses héritiers
    /// - Parameters:
    ///   - patrimoine: le patrimoine
    ///   - decedent: défunt
    ///   - year: année du décès
    func transferOwnershipOf(assets      : inout Assets,
                             liabilities : inout Liabilities,
                             of decedent : Adult) {
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
                            spouseFiscalOption : spouseFiscalOption)
        // transférer les passifs
        transferOwnershipOf(liabilities        : &liabilities,
                            decedentName       : decedent.displayName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption)
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
    fileprivate func transferOwnershipOf(assets             : inout Assets,
                                         decedentName       : String,
                                         chidrenNames       : [String]?,
                                         spouseName         : String?,
                                         spouseFiscalOption : InheritanceFiscalOption?) {
        for idx in assets.periodicInvests.items.indices where assets.periodicInvests.items[idx].value(atEndOf: year) > 0 {
            switch assets.periodicInvests[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, let clause):
                    var newClause = clause
                    // régles de transmission particulières pour l'Assurance Vie
                    try! assets.periodicInvests[idx]
                        .ownership.transferLifeInsurance(
                            of           : decedentName,
                            spouseName   : spouseName,
                            childrenName : chidrenNames,
                            accordingTo  : &newClause)
                    assets.periodicInvests[idx].type = .lifeInsurance(periodicSocialTaxes : periodicSocialTaxes,
                                                                      clause              : newClause)

                default:
                    try! assets.periodicInvests[idx]
                        .ownership.transferOwnershipOf(
                            decedentName       : decedentName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption)
            }
        }
        for idx in assets.freeInvests.items.indices where assets.freeInvests.items[idx].value(atEndOf: year) > 0 {
            assets.freeInvests[idx].initializeCurrentInterestsAfterTransmission(yearOfTransmission: year)
            switch assets.freeInvests[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, let clause):
                    var newClause = clause
                    // régles de transmission particulières pour l'Assurance Vie
                    try! assets.freeInvests[idx]
                        .ownership.transferLifeInsurance(
                            of           : decedentName,
                            spouseName   : spouseName,
                            childrenName : chidrenNames,
                            accordingTo  : &newClause)
                    assets.freeInvests[idx].type = .lifeInsurance(periodicSocialTaxes : periodicSocialTaxes,
                                                                  clause              : newClause)

                default:
                    try! assets.freeInvests[idx]
                        .ownership.transferOwnershipOf(
                            decedentName       : decedentName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption)
            }
        }
        for idx in assets.realEstates.items.indices where assets.realEstates.items[idx].value(atEndOf: year) > 0 {
            try! assets.realEstates[idx]
                .ownership.transferOwnershipOf(
                    decedentName       : decedentName,
                    chidrenNames       : chidrenNames,
                    spouseName         : spouseName,
                    spouseFiscalOption : spouseFiscalOption)
        }
        for idx in assets.scpis.items.indices where assets.scpis.items[idx].value(atEndOf: year) > 0 {
            try! assets.scpis.items[idx]
                .ownership.transferOwnershipOf(
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
    fileprivate func transferOwnershipOf(liabilities        : inout Liabilities,
                                         decedentName       : String,
                                         chidrenNames       : [String]?,
                                         spouseName         : String?,
                                         spouseFiscalOption : InheritanceFiscalOption?) {
        // transférer les emprunts
        for idx in liabilities.loans.items.indices where liabilities.loans.items[idx].value(atEndOf: year) > 0 {
            try! liabilities.loans.items[idx]
                .ownership
                .transferOwnershipOf(
                    decedentName       : decedentName,
                    chidrenNames       : chidrenNames,
                    spouseName         : spouseName,
                    spouseFiscalOption : spouseFiscalOption)
        }
        // transférer les dettes
        for idx in liabilities.debts.items.indices {
            try! liabilities.debts.items[idx]
                .ownership
                .transferOwnershipOf(
                    decedentName       : decedentName,
                    chidrenNames       : chidrenNames,
                    spouseName         : spouseName,
                    spouseFiscalOption : spouseFiscalOption)
        }
    }
}