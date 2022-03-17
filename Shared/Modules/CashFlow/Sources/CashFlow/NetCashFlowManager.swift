//
//  NetCashFlowManager.swift
//  Patrimoine
//

//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import AppFoundation
import NamedValue
import Ownership
import PersonModel
import PatrimoineModel
import SimulationLogger

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.NetCashFlowManager")

struct NetCashFlowManager {
    /// Capitaliser les intérêts des investissements financiers libres
    /// - Parameters:
    ///   - year: à la fin de cette année
    func capitalizeFreeInvestments(in patrimoine : Patrimoin,
                                   atEndOf year  : Int) {
        for idx in patrimoine.assets.freeInvests.items.indices {
            try! patrimoine.assets.freeInvests[idx].capitalize(atEndOf: year)
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    /// Investir les capitaux dans des actifs financiers détenus en PP indivis par chaque Adulte récipiendaire des capitaux
    /// - Parameters:
    ///   - ownedCapitals: capitaux à investir [nom du détenteur, du capital]
    ///   - year: année de l'investissement
    func investCapital(ownedCapitals : NameValueDico,
                       in patrimoine : Patrimoin,
                       atEndOf year  : Int) {
        ownedCapitals.forEach { (name, capital) in
            if capital != 0,
               let member = Patrimoin.familyProvider?.member(withName: name),
               member.isAlive(atEndOf: year) {
                
                // trier par capital décroissant
                patrimoine.assets.freeInvests.items.sort(by: {
                    $0.ownedValue(by                  : name,
                                  atEndOf             : year - 1,
                                  withOwnershipNature : .all,
                                  evaluatedFraction   : .ownedValue) >
                        $1.ownedValue(by                  : name,
                                      atEndOf             : year - 1,
                                      withOwnershipNature : .all,
                                      evaluatedFraction   : .ownedValue)
                })
                
                // investir en priorité dans une assurance vie
                for idx in patrimoine.assets.freeInvests.items.indices {
                    switch patrimoine.assets.freeInvests[idx].type {
                        case .lifeInsurance(let periodicSocialTaxes, _):
                            if periodicSocialTaxes &&
                                patrimoine.assets.freeInvests[idx].ownership.hasAUniqueFullOwner(named: name) {
                                // investir la totalité du cash
                                patrimoine.assets.freeInvests[idx].deposit(capital)
                                return
                            }
                        default: break
                    }
                }
                for idx in patrimoine.assets.freeInvests.items.indices {
                    switch patrimoine.assets.freeInvests[idx].type {
                        case .lifeInsurance(let periodicSocialTaxes, _):
                            if !periodicSocialTaxes &&
                                patrimoine.assets.freeInvests[idx].ownership.hasAUniqueFullOwner(named: name) {
                                // investir la totalité du cash
                                patrimoine.assets.freeInvests[idx].deposit(capital)
                                return
                            }
                        default: break
                    }
                }
                
                // si pas d'assurance vie alors investir dans un PEA
                for idx in patrimoine.assets.freeInvests.items.indices
                where patrimoine.assets.freeInvests[idx].type == .pea
                    && patrimoine.assets.freeInvests[idx].ownership.hasAUniqueFullOwner(named: name) {
                    // investir la totalité du cash
                    patrimoine.assets.freeInvests[idx].deposit(capital)
                    return
                }
                
                // si pas d'assurance vie ni de PEA alors investir dans un autre placement
                for idx in patrimoine.assets.freeInvests.items.indices
                where patrimoine.assets.freeInvests[idx].type == .other
                    && patrimoine.assets.freeInvests[idx].ownership.hasAUniqueFullOwner(named: name) {
                    // investir la totalité du cash
                    patrimoine.assets.freeInvests[idx].deposit(capital)
                    return
                }
                
                customLog.log(level: .info, "Il n'y a plus de réceptacle pour receuillir les capitaux reçus par \(name) en \(year)")
                SimulationLogger.shared.log(logTopic: .simulationEvent,
                                            message: "Il n'y a plus de réceptacle pour receuillir les capitaux reçus par \(name) en \(year)")
            }
        }
    }
    // swiftlint :enable :this cyclomatic_complexity

    /// Ajouter la capacité d'épargne à l'investissement libre de type Assurance vie de meilleur rendement
    /// dont un des adultes est un des PP
    /// - Parameters:
    ///   - amount: capacité d'épargne = montant à investir
    ///   - adultsName: tableau de noms des adultes de la famille
    func investNetCashFlow(amount         : Double,
                           in patrimoine  : Patrimoin,
                           for adultsName : [String]) {
        // trier par rendement décroissant
        patrimoine.assets.freeInvests.items.sort(by: {$0.averageInterestRateNetOfInflation > $1.averageInterestRateNetOfInflation})
        
        // investir en priorité dans une assurance vie
        for idx in patrimoine.assets.freeInvests.items.indices {
            switch patrimoine.assets.freeInvests[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if periodicSocialTaxes
                        && amount != 0
                        && patrimoine.assets.freeInvests[idx].hasAFullOwner(in: adultsName) {
                        // investir la totalité du cash
                        patrimoine.assets.freeInvests[idx].deposit(amount)
                        return
                    }
                default: break
            }
        }
        for idx in patrimoine.assets.freeInvests.items.indices {
            switch patrimoine.assets.freeInvests[idx].type {
                case .lifeInsurance(let periodicSocialTaxes, _):
                    if !periodicSocialTaxes
                        && amount != 0
                        && patrimoine.assets.freeInvests[idx].hasAFullOwner(in: adultsName) {
                        // investir la totalité du cash
                        patrimoine.assets.freeInvests[idx].deposit(amount)
                        return
                    }
                default: break
            }
        }
        
        // si pas d'assurance vie alors investir dans un PEA
        for idx in patrimoine.assets.freeInvests.items.indices
        where patrimoine.assets.freeInvests[idx].type == .pea
            && patrimoine.assets.freeInvests[idx].hasAFullOwner(in: adultsName) {
            // investir la totalité du cash
            patrimoine.assets.freeInvests[idx].deposit(amount)
            return
        }
        // si pas d'assurance vie ni de PEA alors investir dans un autre placement
        for idx in patrimoine.assets.freeInvests.items.indices
        where patrimoine.assets.freeInvests[idx].type == .other
            && patrimoine.assets.freeInvests[idx].hasAFullOwner(in: adultsName) {
            // investir la totalité du cash
            patrimoine.assets.freeInvests[idx].deposit(amount)
            return
        }
        
        customLog.log(level: .info, "Il n'y a plus de réceptacle pour receuillir les flux de trésorerie positifs")
        print("Il n'y a plus de réceptacle pour receuillir les flux de trésorerie positifs")
    }
    
    /// Calcule la valeur cumulée des FreeInvestments possédée en partie en PP par une personnne
    /// - Parameters:
    ///   - name: nom de la pesonne
    ///   - year: année d'évaluation
    /// - Returns: valeur économique cumulée des FreeInvestments possédés en PP
    /// - On ne tient compte que des actifs détenus au moins en partie en PP
    fileprivate func totalFreeInvestementsValue(ownedBy name  : String,
                                                in patrimoine : Patrimoin,
                                                atEndOf year  : Int) -> Double {
        patrimoine.assets.freeInvests.items.reduce(0) { result, freeInvest in
            if freeInvest.ownership.hasAFullOwner(named: name) {
                return result + freeInvest.ownedValue(by                : name,
                                                      atEndOf           : year,
                                                      evaluationContext : .patrimoine)
            } else {
                return result
            }
        }
    }
    
    /// Retirer `amount` du capital des personnes dans la liste `adultsName` seulement.
    ///
    /// L'ordre de retrait est le suivant:
    ///  * Le taux de rendement le moins élevé d'abord
    ///  * D'abord PEA ensuite Assurance vie puis autre; par taux de rendement décroissant
    ///  * Retirer le montant d'un investissement libre dont la personne est un des PP.
    /// - Note:
    ///     Pour une personne et un bien donné on peut retirer de ce bien un Montant maximum de:
    ///     * Bien non démembré = part de la valeur actuelle détenue en PP par la personne
    ///     * Bien démembré        = part de la valeur actuelle détenue en UF+NP par la même personne
    ///     * Bien démembré        + part des revenus générés depuis son acquisition (si la personne est détentrice d'UF supplémentaire)
    fileprivate func getCashFlowFromInvestement(in patrimoine             : Patrimoin,
                                                of name                   : String = "",
                                                _ year                    : Int,
                                                _ amountRemainingToRemove : inout Double,
                                                _ totalTaxableInterests   : inout Double,
                                                _ lifeInsuranceRebate     : inout Double,
                                                _ taxes                   : inout [TaxeCategory: NamedValueTable]) {
        guard amountRemainingToRemove > 0.0 else {
            return
        }
        
        // PEA: retirer le montant d'un investissement libre: d'abord le PEA procurant le moins bon rendement
        for idx in patrimoine.assets.freeInvests.items.indices
        where patrimoine.assets.freeInvests[idx].type == .pea {
            // tant que l'on a pas retiré le montant souhaité
            // retirer le montant du PEA s'il y en avait assez à la fin de l'année dernière
            let removal = patrimoine.assets
                .freeInvests[idx].withdrawal(netAmount : amountRemainingToRemove,
                                             for       : name,
                                             verbose   : true)
            amountRemainingToRemove -= removal.revenue
            // IRPP: les plus values PEA ne sont pas imposables à l'IRPP
            // Prélèvements sociaux: prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
            if amountRemainingToRemove <= 0.0 {
                return
            }
        }
        
        // ASSURANCE VIE: si le solde des PEA n'était pas suffisant alors retirer de l'Assurances vie procurant le moins bon rendement
        for idx in patrimoine.assets.freeInvests.items.indices {
            switch patrimoine.assets.freeInvests[idx].type {
                case .lifeInsurance:
                    // tant que l'on a pas retiré le montant souhaité
                    // retirer le montant de l'Assurances vie s'il y en avait assez à la fin de l'année dernière
                    let removal = patrimoine.assets
                        .freeInvests[idx].withdrawal(netAmount : amountRemainingToRemove,
                                                     for       : name,
                                                     verbose   : true)
                    amountRemainingToRemove -= removal.revenue
                    // IRPP: part des produit de la liquidation inscrit en compte courant imposable à l'IRPP après déduction de ce qu'il reste de franchise
                    var taxableInterests: Double
                    // apply rebate if some is remaining
                    taxableInterests = zeroOrPositive(removal.taxableInterests - lifeInsuranceRebate)
                    lifeInsuranceRebate -= (removal.taxableInterests - taxableInterests)
                    // géré comme un revenu en report d'imposition (dette)
                    totalTaxableInterests += taxableInterests
                    // Prélèvements sociaux => prélevés à la source sur le montant brut du retrait donc pas à payer dans le futur
                    if amountRemainingToRemove <= 0.0 {
                        return
                    }
                default:
                    break
            }
        }
        
        // AUTRE: retirer le montant d'un investissement libre: d'abord celui procurant le moins bon rendement
        for idx in patrimoine.assets.freeInvests.items.indices
        where patrimoine.assets.freeInvests[idx].type == .other {
            // tant que l'on a pas retiré le montant souhaité
            // retirer le montant s'il y en avait assez à la fin de l'année dernière
            let removal = patrimoine.assets
                .freeInvests[idx].withdrawal(netAmount : amountRemainingToRemove,
                                             for       : name,
                                             verbose   : true)
            amountRemainingToRemove -= removal.revenue
            // IRPP: les plus values sont imposables à l'IRPP
            // géré comme un revenu en report d'imposition (dette)
            totalTaxableInterests += removal.taxableInterests
            // Prélèvements sociaux
            taxes[.socialTaxes]?.namedValues.append(NamedValue(name : patrimoine.assets.freeInvests[idx].name,
                                                               value: removal.socialTaxes))
            if amountRemainingToRemove <= 0.0 {
                return
            }
        }
    }
    
    /// Retirer `amount` du capital des personnes dans la liste `adultsName` seulement.
    ///
    /// Ordre:
    ///  * Retirer le cash du capital de la personne la plus riche d'abord.
    ///  * Le taux de rendement le moins élevé d'abord
    ///  * D'abord PEA ensuite Assurance vie puis autre; par taux de rendement décroissant
    ///  * Retirer le montant d'un investissement libre dont la personne est un des PP.
    ///
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   - amount: découvert en fin d'année à combler = montant à désinvestir
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    ///   - year: année en cours
    ///   - adultsName: personnes à qui l'on va retirer le cash demandé.
    ///   - taxes: taxes à payer sur les retraits de cash
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    /// - Returns: somme des intérets taxables générés par les retraits (en report d'mposition sur lannée suivante)
    func getCashFromInvestement(thisAmount amount   : Double,
                                in patrimoine       : Patrimoin,
                                atEndOf year        : Int,
                                for adultsName      : [String],
                                taxes               : inout [TaxeCategory: NamedValueTable],
                                lifeInsuranceRebate : inout Double) throws -> Double {
        var amountRemainingToRemove = amount
        var totalTaxableInterests   = 0.0
        
        // trier les adultes vivants par ordre de capital décroissant
        // (en termes de FreeInvestement possédé en partie en PP)
        var sortedAdultNames = [String]()
        if adultsName.count > 1 {
            sortedAdultNames = adultsName.sorted {
                totalFreeInvestementsValue(ownedBy : $0,
                                           in      : patrimoine,
                                           atEndOf : year) >
                    totalFreeInvestementsValue(ownedBy : $1,
                                               in      : patrimoine,
                                               atEndOf : year)
            }
        } else {
            sortedAdultNames = adultsName
        }
//        sortedAdultNames.forEach { name in
//            print("nom: \(name)")
//            print("richesse disponible (freeInvest en partie en PP): \(totalFreeInvestementsValue(ownedBy: name, in: patrimoine, atEndOf: year).rounded())")
//        }

        // trier par taux de rendement croissant
        patrimoine.assets.freeInvests.items.sort(by: {$0.averageInterestRateNetOfInflation < $1.averageInterestRateNetOfInflation})

        if adultsName.count == 0 {
            // s'il n'y a plus d'adulte vivant on prend dans le premier actif qui vient
            // ce sont les héritiers qui payent
            getCashFlowFromInvestement(in: patrimoine,
                                       year,
                                       &amountRemainingToRemove,
                                       &totalTaxableInterests,
                                       &lifeInsuranceRebate,
                                       &taxes)
        } else {
            // retirer le cash du capital de la personne la plus riche d'abord
            for adultName in sortedAdultNames {
                getCashFlowFromInvestement(in: patrimoine,
                                           of: adultName,
                                           year,
                                           &amountRemainingToRemove,
                                           &totalTaxableInterests,
                                           &lifeInsuranceRebate,
                                           &taxes)
                if amountRemainingToRemove <= 0 {
                    return totalTaxableInterests
                }
            }
        }
        
        if amountRemainingToRemove > 0.0 {
            // on a pas pu retirer suffisament pour couvrir le déficit de cash de l'année
            throw CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
        }
        
        return totalTaxableInterests
    }

}
