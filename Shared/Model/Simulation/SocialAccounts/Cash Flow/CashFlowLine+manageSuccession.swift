//
//  CashFlowLine+manageSuccession.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 12/07/2021.
//

import Foundation

extension CashFlowLine {
    mutating func updateSuccessionsTaxes(of family: Family) {
        family.members.items.forEach { member in
            // successions légales
            var taxe: Double = 0
            successions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.person == member {
                        taxe += inheritance.tax
                    }
                }
            }
            // on ne prend en compte que les droits de succession des adultes dans leur CashFlow commun
            if member is Adult {
                taxes.perCategory[.succession]?.namedValues
                    .append((name  : member.displayName,
                             value : taxe))
            } else {
                // TODO: - créer un CashFlow pour chaque enfant
            }
            
            // succession assurances vies
            taxe = 0
            lifeInsSuccessions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.person == member {
                        taxe += inheritance.tax
                    }
                }
            }
            // on ne prend en compte que les droits de succession des adultes dans leur CashFlow commun
            if member is Adult {
                taxes.perCategory[.liSuccession]?.namedValues
                    .append((name  : member.displayName,
                             value : taxe))
            } else {
                // TODO: - créer un CashFlow pour chaque enfant
            }
        }
    }
    
    /// Gérer les succession de l'année.
    ///
    /// Identifier toutes les successions de l'année.
    ///
    /// Calculer les droits de succession des personnes décédées dans l'année.
    ///
    /// Transférer les biens des personnes décédées dans l'année vers ses héritiers.
    ///
    /// - Parameters:
    ///   - run: numéro du run en cours de calcul
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine de la famille
    mutating func manageSuccession(run             : Int,
                                   of family       : Family,
                                   with patrimoine : Patrimoin) {
        // FIXME: - en fait il faudrait traiter les sucessions en séquences: calcul taxe => transmission puis calcul tax => transmission
        // identification des personnes décédées dans l'année
        let decedents = family.deceasedAdults(during: year)
        
        // ajouter les droits de succession (légales et assurances vie) aux taxes
        var totalLegalSuccessionTax = 0.0
        var totalLiSuccessionTax    = 0.0
        // pour chaque défunt
        decedents.forEach { decedent in
            SimulationLogger.shared.log(run: run,
                                        logTopic: .lifeEvent,
                                        message: "Décès de \(decedent.displayName) en \(year)")
            // calculer les droits de successions légales
            let legalSuccessionManager = LegalSuccessionManager()
            let succession =
                legalSuccessionManager.legalSuccession(in      : patrimoine,
                                                       of      : decedent,
                                                       atEndOf : year)
            successions.append(succession)
            totalLegalSuccessionTax += succession.tax
            
            // calculer les droits de transmission assurances vies
            let lifeInsuranceSuccessionManager = LifeInsuranceSuccessionManager()
            let liSuccession =
                lifeInsuranceSuccessionManager.lifeInsuraceSuccession(in      : patrimoine,
                                                                      of      : decedent,
                                                                      atEndOf : year)
            lifeInsSuccessions.append(liSuccession)
            totalLiSuccessionTax += liSuccession.tax
            
            // transférer les biens d'un défunt vers ses héritiers
            let ownershipManager = OwnershipManager()
            ownershipManager.transferOwnershipOf(of       : patrimoine,
                                                 decedent : decedent,
                                                 atEndOf  : year)
        }
        
        // mettre à jour les taxes de l'année avec les droits de successions de l'année
        updateSuccessionsTaxes(of: family)
    }
    
}
