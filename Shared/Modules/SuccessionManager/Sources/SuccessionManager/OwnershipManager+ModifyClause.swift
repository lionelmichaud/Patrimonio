//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 13/10/2021.
//

import Foundation
import Ownership
import PersonModel
import FamilyModel
import AssetsModel
import Liabilities
import SimulationLogger

extension OwnershipManager {
    
    /// Modifie une ou plusieur clauses d'AV pour permettre à chaque enfant de payer ses droits de succession
    /// - Parameters:
    ///   - decedentName: adulte décédé
    ///   - conjoint: l'adulte survivant au décès du premier adulte
    ///   - assets: Actifs de la famille
    ///   - liabilities: Passifs de la famille
    ///   - taxes: les droits de succession à payer par chaque enfant
    func modifyLifeInsuranceClauseIfNecessaryAndPossible
    (of decedentName             : String,
     conjointName                : String,
     withAssets assets           : inout Assets,
     withLiabilities liabilities : Liabilities,
     toPayFor taxes              : NameValueDico) throws {
        var missingCapitals = missingCapital(of              : decedentName,
                                             withAssets      : assets,
                                             withLiabilities : liabilities,
                                             toPayFor        : taxes)
        
        guard missingCapitals.values.sum() > 0.0 else {
            // il ne manque rien à personne
            return
        }
        
        // trier les AV avec clause bénéficiaire à option par valeur possédée par le défunt croissantes
        // prendre les valeurs à la fin de l'année précédente
        assets
            .freeInvests
            .items
            .sort {
                $0.ownedValue(by: decedentName, atEndOf: year - 1, evaluationContext: .patrimoine) <
                    $1.ownedValue(by: decedentName, atEndOf: year - 1, evaluationContext: .patrimoine)
            }
        
        for idx in assets.freeInvests.items.indices {
            //print(String(describing: patrimoine.assets.freeInvests.items[idx]))
            try modifyClause(of           : &assets.freeInvests.items[idx],
                             toGet        : &missingCapitals,
                             decedentName : decedentName,
                             conjointName : conjointName)
            
            // arrêter quand les capitaux des enfants seront suffisants pour payer
            if missingCapitals.values.sum() == 0.0 { break }
        }
        
        if missingCapitals.values.sum() > 0 {
            SimulationLogger.shared.log(run      : run,
                                        logTopic : .other,
                                        message  : "Les enfants ne peuvent pas payer les droits de succession au décès de \(decedentName) en \(year)")
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
    fileprivate func missingCapital
    (of decedentName             : String,
     withAssets assets           : Assets,
     withLiabilities liabilities : Liabilities,
     toPayFor taxes              : NameValueDico) -> NameValueDico {
        // cumuler les valeurs d'actif net que chaque enfant peut vendre après transmission
        let childrenSellableCapital =
            childrenSellableCapitalAfterInheritance(receivedFrom    : decedentName,
                                                    withAssets      : assets,
                                                    withLiabilities : liabilities)
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
    fileprivate func childrenSellableCapitalAfterInheritance
    (receivedFrom decedentName   : String,
     withAssets assets           : Assets,
     withLiabilities liabilities : Liabilities) -> NameValueDico {
        // simuler les transmisssions pour calculer ce que les enfants
        // hériterons en PP sans modifier aucune clause d'AV
        var assetsCopy      = assets
        var liabilitiesCopy = liabilities
        transferOwnershipOf(assets      : &assetsCopy,
                            liabilities : &liabilitiesCopy,
                            of          : decedentName)
        
        // cumuler les actifs nets dont les enfants sont PP après transmission
        return childrenNetSellableAssets(withAssets      : assetsCopy,
                                         withLiabilities : liabilitiesCopy)
    }
    
    /// Actif net vendable détenu par l'ensemble des enfants à la fin de l'année `year`
    /// pour à sa valeur patrimoniale.
    /// - Parameters:
    ///   - family: la famille
    ///   - assets: actifs de la famille
    ///   - liabilities: passifs de la famille
    ///   - year: année
    /// - Returns: actif net vendable détenu par l'ensemble des enfants à la fin de l'année
    fileprivate func childrenNetSellableAssets
    (withAssets assets           : Assets,
     withLiabilities liabilities : Liabilities) -> NameValueDico {
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
    fileprivate func modifyClause(of freeInvest        : inout FreeInvestement,
                                  toGet missingCapital : inout NameValueDico,
                                  decedentName         : String,
                                  conjointName         : String) throws {
        // ne considérer que :
        // - les assurance vie
        // - avec clause à option
        // - dont le défunt est un des PP
        switch freeInvest.type {
            case let InvestementKind.lifeInsurance(periodicSocialTaxes, clause):
                guard clause.isOptional && freeInvest.ownership.hasAFullOwner(named: decedentName) else {
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
                var newClause = clause
                newClause.isOptional = false
                newClause.fullRecipients = []
                //  - capital décès total versé aux enfants (somme)
                let givenToChildren = min(decedentOwnedValue, missingCapital.values.sum())
                //  - part du capital décès versée aux enfants (somme) en PP
                let partDesEnfants = givenToChildren * 100.0 / decedentOwnedValue
                let childrenAlive  = family.childrenAliveName(atEndOf: year)
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

                guard newClause.isValid else {
                    let invalid = newClause
                    customLogOwnershipManager.log(level: .error, "'modifyClause' a généré une 'clause' invalide \(invalid, privacy: .public)")
                    throw OwnershipError.invalidOwnership
                }

                freeInvest.type = .lifeInsurance(periodicSocialTaxes : periodicSocialTaxes,
                                                 clause              : newClause)
                print("Nouvelle clause:\n\(String(describing: newClause))")
                
                // Mettre à jour les `missingCapital` en conséquence
                for childName in missingCapital.keys {
                    missingCapital[childName]! -= givenToChildren / childrenAlive!.count.double()
                    missingCapital[childName]! = max(0.0, missingCapital[childName]!)
                }
                
            default:
                // pas une assurance vie
                return
        }
    }

}
