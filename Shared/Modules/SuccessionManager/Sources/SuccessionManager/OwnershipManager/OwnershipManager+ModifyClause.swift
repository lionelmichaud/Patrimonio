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
    
    /// Modifie une ou plusieurs clauses d'AV pour permettre à chaque enfant de payer ses droits de succession
    /// - Parameters:
    ///   - decedentName: adulte décédé
    ///   - conjointName: l'adulte survivant au décès du premier adulte
    ///   - assets: Actifs de la famille
    ///   - liabilities: Passifs de la famille
    ///   - capitauxDecesRecusNet: capitaux décès nets de taxes de transmssion reçus par les héritiers
    ///   - taxes: les droits de succession à payer par chaque enfant
    func modifyLifeInsuranceClauseIfNecessaryAndPossible /// swiftlint:disable:this function_parameter_count
    (decedentName                : String,
     conjointName                : String,
     withAssets assets           : inout Assets,
     withLiabilities liabilities : Liabilities,
     toPayFor taxes              : NameValueDico,
     capitauxDecesRecusNet       : LifeInsuranceSuccessionManager.NameCapitauxDecesDico,
     verbose                     : Bool = false) throws {
        
        var missingCapitals = missingCapital(decedentName          : decedentName,
                                             withAssets            : assets,
                                             withLiabilities       : liabilities,
                                             toPayFor              : taxes,
                                             capitauxDecesRecusNet : capitauxDecesRecusNet,
                                             verbose               : verbose)
        
        guard missingCapitals.values.sum() > 0.0 else {
            // il ne manque rien à personne
            if verbose {
                print("Il ne manque pas de capital aux enfants pour payer les taxes et les droits de succession")
            }
            return
        }
        
        // trier les AV avec clause bénéficiaire à option par valeur croissantes possédée par le défunt
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
        } else if verbose {
            print("=> Les enfants pourront payer grâce à l'exercice de clauses à option")
        }
    }
    
    /// Calcule les capitaux manquant à chaque enfant pour payer ses droits de succcession `taxes`
    /// - Parameters:
    ///   - decedentName: adulte décédé
    ///   - assets: Actifs de la famille
    ///   - liabilities: Passifs de la famille
    ///   - taxes: les droits de succession à payer par chaque enfant
    ///   - capitauxDecesRecusNet: capitaux décès nets de taxes de transmssion reçus par les héritiers
    /// - Returns: capitaux manquant à chaque enfant pour payer ses droits de succcession
    func missingCapital
    (decedentName                : String,
     withAssets assets           : Assets,
     withLiabilities liabilities : Liabilities,
     toPayFor taxes              : NameValueDico,
     capitauxDecesRecusNet       : LifeInsuranceSuccessionManager.NameCapitauxDecesDico,
     verbose                     : Bool = false) -> NameValueDico {
        
        // l'allocation aux enfants d'une partie de l'option va accroitre leur capitaux décès
        // donc accroitre leur taxes => il faut en tenir compte en augmenant leur option d'autan
        let correctionFactor = 1.3
        
        // cumuler les valeurs d'actif net que chaque enfant peut vendre après transmission
        let childrenSellableCapital =
            childrenNetSellableAssetsAfterInheritance(receivedFrom    : decedentName,
                                                      withAssets      : assets,
                                                      withLiabilities : liabilities)
        
        // calculer les capitaux manquants à chaque enfants pour pouvoir payer ses droits de succession
        var missingCapital = NameValueDico()
        taxes.forEach { childrenName, tax in
            let tax = tax * correctionFactor
            let sellableCapital      = childrenSellableCapital[childrenName] ?? 0.0
            let capitalDecesBrutRecu = capitauxDecesRecusNet[childrenName]?.received.brut ?? 0.0
            missingCapital[childrenName] = max(0.0, tax - (sellableCapital + capitalDecesBrutRecu))
            if verbose {
                print(childrenName)
                print("  > Taxe & Droits de succession à payer:\n     -\(tax.k€String)")
                print("  > Capital cessible détenu après succession:\n     +\(sellableCapital.k€String)")
                print("  > Capital décès brut reçus à la succession:\n     +\(capitalDecesBrutRecu.k€String)")
                print("  > Capital manquant à pour payer les droits de succession:\n     = \(missingCapital[childrenName]!.k€String)\n")
            }
        }
        if verbose {
            print("> Capital manquant aux enfants pour payer les droits de succession:\n \(missingCapital) \n Total = \(missingCapital.values.sum().k€String)")
        }
        
        return missingCapital
    }
    
    /// Calcule le cumul des valeurs d'actif net que les enfants peuvent vendre après transmission
    /// - Parameters:
    ///   - decedentName: adulte décédé
    ///   - assets: Actifs de la famille
    ///   - liabilities: Passifs de la famille
    /// - Returns: cumul des valeurs d'actif net que les enfants peuvent vendre après transmission
    func childrenNetSellableAssetsAfterInheritance
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
    
    /// Actif net vendable détenu par chaque enfant à la fin de l'année `year`
    /// à sa valeur patrimoniale.
    /// - Parameters:
    ///   - assets: actifs de la famille
    ///   - liabilities: passifs de la famille
    /// - Returns: actif net vendable détenu par l'ensemble des enfants à la fin de l'année
    func childrenNetSellableAssets(withAssets assets           : Assets,
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
    func modifyClause(of freeInvest        : inout FreeInvestement,
                      toGet missingCapital : inout NameValueDico,
                      decedentName         : String,
                      conjointName         : String,
                      verbose              : Bool = false) throws {
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
                if verbose {
                    print("Assurance: \(freeInvest.name)\n Valeur possédée en \(year-1): \(decedentOwnedValue.k€String)")
                }
                
                // modifier la clause bénéficiaire d'assurance vie
                var newClause = clause
                newClause.isOptional = false
                newClause.fullRecipients = []
                
                //  - Capital décès total à verser aux enfants (somme) pour pouvoir payer les droits de succession
                //    Chaque enfants vivant recevant la même part, la somme donnée à chaque enfant est alignée sur
                //    celui qui a le plus grand besoin
                let besoinMax = missingCapital.values.max()!
                let childrenAlive  = family.childrenAliveName(atEndOf: year)
                let besoinTotal = besoinMax * childrenAlive!.count.double()
                let givenToChildren = min(decedentOwnedValue, besoinTotal)
                
                //  - part du capital décès versée aux enfants (somme) en PP
                let partDesEnfants = givenToChildren * 100.0 / decedentOwnedValue
                childrenAlive?.forEach { childrenName in
                    newClause.fullRecipients.append(Owner(name     : childrenName,
                                                          fraction : partDesEnfants / childrenAlive!.count.double()))
                }
                
                //  - part du capital versée au conjoint en PP
                let partDuConjoint = 100.0 - partDesEnfants
                newClause.fullRecipients.append(Owner(name     : conjointName,
                                                      fraction : partDuConjoint))
                
                // éliminer les parts nulles éventuelles
                newClause.fullRecipients.groupShares()
                
                if verbose {
                    print("Part des enfants: \(partDesEnfants) % = \(givenToChildren.k€String)")
                    print("Part du conjoint: \(partDuConjoint) % = \((decedentOwnedValue - givenToChildren).k€String)")
                }
                
                guard newClause.isValid else {
                    let invalid = newClause
                    customLogOwnershipManager.log(level: .error, "'modifyClause' a généré une 'clause' invalide \(invalid, privacy: .public)")
                    throw OwnershipError.invalidOwnership
                }
                
                freeInvest.type = .lifeInsurance(periodicSocialTaxes : periodicSocialTaxes,
                                                 clause              : newClause)
                if verbose {
                    print("Nouvelle clause:\n\(String(describing: newClause))")
                }
                
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
    
    /// Modifier les clauses d'AV dont le défunt est un des donataires
    /// - Parameters:
    ///   - decedentName: Nom du défunt
    ///   - childrenName: nom des enfants du défunt
    ///   - assets: les actifs de la famille à modifier
    func modifyClausesWhereDecedentIsFuturRecipient
    (decedentName      : String,
     childrenName      : [String]?,
     withAssets assets : inout Assets) throws {
        
        for idx in assets.freeInvests.items.indices {
            switch assets.freeInvests[idx].type {
                case let InvestementKind.lifeInsurance(periodicSocialTaxes, clause):
                    var newClause = clause
                    manageRecipientDeath(decedentName : decedentName,
                                         withClause   : &newClause,
                                         childrenName : childrenName)
                    
                    guard newClause.isValid else {
                        let invalid = newClause
                        customLogOwnershipManager.log(level: .error, "a généré une 'clause' invalide \(invalid, privacy: .public)")
                        throw ClauseError.invalidClause
                    }
                    assets.freeInvests[idx].type = .lifeInsurance(periodicSocialTaxes : periodicSocialTaxes,
                                                                  clause              : newClause)
                    
                default:
                    break
            }
        }
        
        for idx in assets.periodicInvests.items.indices {
            switch assets.periodicInvests[idx].type {
                case let InvestementKind.lifeInsurance(periodicSocialTaxes, clause):
                    var newClause = clause
                    manageRecipientDeath(decedentName : decedentName,
                                         withClause   : &newClause,
                                         childrenName : childrenName)
                    
                    guard newClause.isValid else {
                        let invalid = newClause
                        customLogOwnershipManager.log(level: .error, "a généré une 'clause' invalide \(invalid, privacy: .public)")
                        throw ClauseError.invalidClause
                    }
                    assets.periodicInvests[idx].type = .lifeInsurance(periodicSocialTaxes : periodicSocialTaxes,
                                                                      clause              : newClause)
                    
                default:
                    break
            }
        }
    }
    
    /// Modifier une clause d'AV si le défunt est un des donataires
    /// - Parameters:
    ///   - decedentName: Nom du défunt
    ///   - clause: la clause à modifier
    ///   - childrenName: nom des enfants du défunt
    func manageRecipientDeath(decedentName      : String,
                              withClause clause : inout Clause,
                              childrenName      : [String]?) {
        if clause.isDismembered {
            // (A) la clause est est démembrée
            if clause.usufructRecipient == decedentName {
                // (1) le défunt est l'usufruitier désigné dans la clause
                // -> remembrer la clause
                clause.isDismembered = false
                clause.fullRecipients = clause.bareRecipients.map {
                    Owner(name     : $0,
                          fraction : 100.0 / clause.bareRecipients.count.double())
                }
                clause.usufructRecipient = ""
                clause.bareRecipients = []
                
            } else if clause.bareRecipients.contains(decedentName) {
                // (2) le défunt est un des NP désignés dans la clause
                if clause.bareRecipients.count > 1 {
                    // (a) il y a d'autres NP
                    // -> supprimer le NP
                    clause.bareRecipients
                        .remove(at: clause.bareRecipients.firstIndex(of: decedentName)!)
                    
                } else {
                    // (b) il n'y a pas d'autres NP
                    // -> remembrer la clause
                    clause.isDismembered = false
                    clause.fullRecipients = [Owner(name: clause.usufructRecipient,
                                                   fraction: 100)]
                    clause.usufructRecipient = ""
                    clause.bareRecipients = []
                }
            }
        } else {
            // (B) la clause n'est pas démembrée
            if clause.fullRecipients.contains(ownerName: decedentName) {
                // (1) le défunt est un des PP désignés dans la clause
                if clause.fullRecipients.count > 1 {
                    // (a) il y a d'autres PP dans la clause
                    // -> transférer aux autres PP par parts égales
                    try! clause.fullRecipients.redistributeShare(of: decedentName)
                    
                } else {
                    // (b) il n'y a pas d'autres PP dans la clause
                    // -> transférer aux enfants par parts égales
                    if let childrenName = childrenName {
                        // (1) il ya des enfants héritiers
                        try! clause.fullRecipients.replace(thisOwner : decedentName,
                                                           with      : childrenName)
                        clause.isOptional = false
                    }
                }
            }
        }
    }

}
