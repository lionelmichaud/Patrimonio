//
//  OwnershipManager.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/04/2021.
//

import Foundation
import FiscalModel
import PersonModel
import PatrimoineModel
import AssetsModel
import Liabilities

struct OwnershipManager {
    
    /// Transférer la propriété d'un `patrimoine` d'un défunt `decedent` vers ses héritiers
    /// - Parameters:
    ///   - patrimoine: le patrimoine
    ///   - decedent: défunt
    ///   - year: année du décès
    func transferOwnershipOf(_ patrimoine : Patrimoin,
                             of decedent  : Person,
                             atEndOf year : Int) {
        guard let family = Patrimoin.familyProvider else {
            fatalError("La famille n'est pas définie dans Patrimoin.transferOwnershipOf")
        }
        // rechercher un conjont survivant
        var spouseName         : String?
        var spouseFiscalOption : InheritanceFiscalOption?
        if let decedent = decedent as? Adult, let spouse = family.spouseOf(decedent) {
            if spouse.isAlive(atEndOf: year) {
                spouseName         = spouse.displayName
                spouseFiscalOption = spouse.fiscalOption
            }
        }
        // rechercher des enfants héritiers vivants
        let chidrenNames = family.childrenAliveName(atEndOf: year)
        
        // leur transférer la propriété de tous les biens détenus par le défunt
        transferOwnershipOf(patrimoine         : patrimoine,
                            decedentName       : decedent.displayName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption,
                            atEndOf            : year)
    }
    
    // swiftlint:disable function_parameter_count
    /// Transférer la propriété d'un `patrimoine` d'un défunt `decedent` vers ses héritiers
    /// en fonction de l'option fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    ///   - patrimoine: le patrimoine
    ///   - year: année du décès
    func transferOwnershipOf(patrimoine         : Patrimoin,
                             decedentName       : String,
                             chidrenNames       : [String]?,
                             spouseName         : String?,
                             spouseFiscalOption : InheritanceFiscalOption?,
                             atEndOf year       : Int) {
        // transférer les actifs
        transferOwnershipOf(assets: &patrimoine.assets,
                            decedentName       : decedentName,
                            chidrenNames       : chidrenNames,
                            spouseName         : spouseName,
                            spouseFiscalOption : spouseFiscalOption,
                            atEndOf            : year)
        // transférer les passifs
        transferOwnershipOf(liabilities        : &patrimoine.liabilities,
                            decedentName       : decedentName,
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
    func transferOwnershipOf(assets             : inout Assets,
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
    func transferOwnershipOf(liabilities        : inout Liabilities,
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
