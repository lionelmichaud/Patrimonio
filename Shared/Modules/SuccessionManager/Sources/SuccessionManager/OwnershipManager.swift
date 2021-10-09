//
//  OwnershipManager.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/04/2021.
//

import Foundation
import FiscalModel
import Ownership
import PersonModel
import FamilyModel
import PatrimoineModel
import AssetsModel
import Liabilities
import SimulationLogger

struct OwnershipManager {
    
    // swiftlint:disable function_parameter_count
    
    /// Modifie une ou plusieur clauses d'AV pour permettre à chaque enfant de payer ses droits de succession
    /// - Parameters:
    ///   - decedent: adulte décédé
    ///   - conjoint: l'adulte survivant au décès du premier adulte
    ///   - family: la famille
    ///   - assets: Actifs de la famille
    ///   - liabilities: Passifs de la famille
    ///   - taxes: les droits de succession à payer par chaque enfant
    ///   - year: l'année du décès
    func modifyLifeInsuranceClause
    (of decedent                 : Adult,
     conjoint                    : Adult,
     in family                   : Family,
     withAssets assets           : inout Assets,
     withLiabilities liabilities : Liabilities,
     toPayFor taxes              : NameValueDico,
     atEndOf year                : Int,
     run                         : Int) {
        var missingCapitals = missingCapital(of: decedent,
                                             in: family,
                                             withAssets: &assets,
                                             withLiabilities: liabilities,
                                             toPayFor: taxes, atEndOf: year)
        
        guard missingCapitals.values.sum() > 0.0 else {
            // il ne manque rien à personne
            return
        }
        
        // trier les AV avec clause bénéficiaire à option par valeur possédée par le défunt
        // prendre les valeurs à la fin de l'année précédente
        assets
            .freeInvests
            .items
            .sort {
                $0.ownedValue(by: decedent.displayName, atEndOf: year - 1, evaluationContext: .patrimoine) >
                    $1.ownedValue(by: decedent.displayName, atEndOf: year - 1, evaluationContext: .patrimoine)
            }
        //print(String(describing: patrimoine.assets.freeInvests.items))
        
        for idx in assets.freeInvests.items.indices {
            modifyClause(of           : &assets.freeInvests.items[idx],
                         toGet        : &missingCapitals,
                         decedentName : decedent.displayName,
                         conjointName : conjoint.displayName,
                         in           : family,
                         atEndOf      : year,
                         run)
            
            // arrêter quand les capitaux des enfants seront suffisants pour payer
            if missingCapitals.values.sum() == 0.0 { break }
        }
        
        if missingCapitals.values.sum() > 0 {
            SimulationLogger.shared.log(run      : run,
                                        logTopic : .other,
                                        message  : "Les enfants ne peuvent pas payer les droits de succession au décès de \(decedent.displayName) en \(year)")
        }
    }
    
    /// Calcule les capitaux manquant à chaque enfant pour payer ses droits de succcession `taxes`
    /// - Parameters:
    ///   - decedent: adulte décédé
    ///   - family: la famille
    ///   - assets: Actifs de la famille
    ///   - liabilities: Passifs de la famille
    ///   - taxes: les droits de succession à payer par chaque enfant
    ///   - year: l'année du décès
    /// - Returns: capitaux manquant à chaque enfant pour payer ses droits de succcession
    private func missingCapital
    (of decedent                 : Adult,
     in family                   : Family,
     withAssets assets           : inout Assets,
     withLiabilities liabilities : Liabilities,
     toPayFor taxes              : NameValueDico,
     atEndOf year                : Int) -> NameValueDico {
        // cumuler les valeurs d'actif net que chaque enfant peut vendre après transmission
        let childrenSellableCapital =
            childrenSellableCapitalAfterInheritance(receivedFrom    : decedent,
                                                    inFamily        : family,
                                                    withAssets      : assets,
                                                    withLiabilities : liabilities,
                                                    atEndOf         : year)
        print("> Capital cessible détenu par les enfants après succession:\n \(childrenSellableCapital) \n Total = \(childrenSellableCapital.values.sum().k€String)")
        
        // calculer les capitaux manquants à chaque enfants pour pouvoir payer ses droits de succession
        var missingCapital = NameValueDico()
        taxes.forEach { childrenName, tax in
            let sellableCapital = childrenSellableCapital[childrenName] ?? 0.0
            missingCapital[childrenName] = max(0.0, tax - sellableCapital)
        }
        print("> Capital manquant aux enfants pour payer les droits de succession:\n \(missingCapital) \n Total = \(missingCapital.values.sum().k€String)")
        
        return missingCapital
    }
    
    /// Calcule le cumul des valeurs d'actif net que les enfants peuvent vendre après transmission
    /// - Parameters:
    ///   - decedent: adulte décédé
    ///   - family: la famille
    ///   - assets: Actifs de la famille
    ///   - liabilities: Passifs de la famille
    ///   - year: l'année du décès
    /// - Returns: cumul des valeurs d'actif net que les enfants peuvent vendre après transmission
    private func childrenSellableCapitalAfterInheritance
    (receivedFrom decedent       : Adult,
     inFamily family             : Family,
     withAssets assets           : Assets,
     withLiabilities liabilities : Liabilities,
     atEndOf year                : Int) -> NameValueDico {
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
    private func childrenNetSellableAssets
    (in family                   : Family,
     withAssets assets           : Assets,
     withLiabilities liabilities : Liabilities,
     atEndOf year                : Int) -> NameValueDico {
        var childrenSellableAssets = NameValueDico()
        // Attention: évaluer à la fin de l'année précédente (important pour les FreeInvestment)
        family.childrenAliveName(atEndOf: year)?.forEach { childName in
            childrenSellableAssets[childName] =
                assets.ownedValue(by                  : childName,
                                  atEndOf             : year - 1,
                                  withOwnershipNature : .sellable,
                                  evaluatedFraction   : .ownedValue) +
                liabilities.ownedValue(by                  : childName,
                                       atEndOf             : year - 1,
                                       withOwnershipNature : .sellable,
                                       evaluatedFraction   : .ownedValue)
        }
        return childrenSellableAssets
    }
    
    /// Modifie la clause d'une assurance vie `freeInvest` si nécessaire pour
    /// que chaque enfant puisse payer ses droits de succcession.
    /// Met à jour les `missingCapital` en conséquence.
    /// - Parameters:
    ///   - freeInvest: Inverstissement libre
    ///   - missingCapital: capitaux manquant à chaque enfant pour payer ses droits de succcession
    ///   - decedentName: nom de l'adulte décédé
    ///   - year: l'année du décès
    private func modifyClause(of freeInvest        : inout FreeInvestement,
                              toGet missingCapital : inout NameValueDico,
                              decedentName         : String,
                              conjointName         : String,
                              in family            : Family,
                              atEndOf year         : Int,
                              _ run                : Int) {
        // ne considérer que :
        // - les assurance vie
        // - avec clause à option
        // - dont le défunt est le seul PP
        var newPeriodicSocialTaxes = false
        var newClause = LifeInsuranceClause()
        switch freeInvest.type {
            case let InvestementKind.lifeInsurance(periodicSocialTaxes, clause):
                guard clause.isOptional && freeInvest.ownership.hasAFullOwner(named: decedentName) else {
                    return
                }
                newPeriodicSocialTaxes = periodicSocialTaxes
                newClause = clause
                
            default:
                // pas une assurance vie
                return
        }
        // capital décès
        let decedentOwnedValue = freeInvest.ownedValue(by                : decedentName,
                                                       atEndOf           : year - 1,
                                                       evaluationContext : .patrimoine)
        guard decedentOwnedValue >= 0 else {
            return
        }
        
        SimulationLogger.shared.log(run      : run,
                                    logTopic : .other,
                                    message  : "Exercice de la clause à option de l'assurance \"\(freeInvest.name)\" de \(decedentName) à son décès en \(year) par \(conjointName)")
        print("Assurance: \(freeInvest.name)\n Valeur possédée en \(year-1): \(decedentOwnedValue.k€String)")
        
        // modifier la clause bénéficiaire d'assurance vie
        newClause.isOptional = false
        newClause.fullRecipients = []
        //  - capital décès total versé aux enfants (somme)
        let givenToChildren = min(decedentOwnedValue, missingCapital.values.sum())
        //  - part du capital décès versée aux enfants (somme) en PP
        let partDesEnfants = givenToChildren * 100.0 / decedentOwnedValue
        let childrenAlive = family.childrenAliveName(atEndOf: year)
        childrenAlive?.forEach { childrenName in
            newClause.fullRecipients.append(Owner(name     : childrenName,
                                                  fraction : partDesEnfants / childrenAlive!.count.double()))
        }
        //  - part du capital versée au conjoint en PP
        let partDuConjoint = 100.0 - partDesEnfants
        newClause.fullRecipients.append(Owner(name     : conjointName,
                                              fraction : partDuConjoint))
        
        print("Part des enfants: \(partDesEnfants) % = \(givenToChildren.k€String)")
        print("Part du conjoint: \(partDuConjoint) % = \((decedentOwnedValue - givenToChildren).k€String)")

        freeInvest.type = .lifeInsurance(periodicSocialTaxes : newPeriodicSocialTaxes,
                                         clause              : newClause)
        print("Nouvelle clause:\n \(String(describing: newClause))")

        // Mettre à jour les `missingCapital` en conséquence
        for childName in missingCapital.keys {
            missingCapital[childName]! -= givenToChildren / childrenAlive!.count.double()
        }
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
        for idx in assets.periodicInvests.items.indices where assets.periodicInvests.items[idx].value(atEndOf: year) > 0 {
            switch assets.periodicInvests[idx].type {
                case .lifeInsurance(_, let clause):
                    // régles de transmission particulières pour l'Assurance Vie
                    try! assets.periodicInvests[idx].ownership.transferLifeInsurance(
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
        for idx in assets.freeInvests.items.indices where assets.freeInvests.items[idx].value(atEndOf: year) > 0 {
            assets.freeInvests[idx].initializeCurrentInterestsAfterTransmission(yearOfTransmission: year)
            switch assets.freeInvests[idx].type {
                case .lifeInsurance(_, let clause):
                    // régles de transmission particulières pour l'Assurance Vie
                    try! assets.freeInvests[idx].ownership.transferLifeInsurance(
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
        for idx in assets.realEstates.items.indices where assets.realEstates.items[idx].value(atEndOf: year) > 0 {
            try! assets.realEstates[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
        for idx in assets.scpis.items.indices where assets.scpis.items[idx].value(atEndOf: year) > 0 {
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
        for idx in liabilities.loans.items.indices where liabilities.loans.items[idx].value(atEndOf: year) > 0 {
            try! liabilities.loans.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
        // transférer les dettes
        for idx in liabilities.debts.items.indices {
            try! liabilities.debts.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
    }
    // swiftlint:enable function_parameter_count
}
