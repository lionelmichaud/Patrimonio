//
//  CashFlowLine+manageSuccession.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 12/07/2021.
//

import Foundation
import ModelEnvironment
import PersonModel
import PatrimoineModel

extension CashFlowLine {

    /// Ajoute les droits de succession  aux taxes de l'année de succession.
    ///
    /// On traite séparément les droits de succession dûs par les parents et par les enfants.
    ///
    mutating func updateSuccessionsTaxes(of family: Family) {
        family.members.items.forEach { member in
            // successions légales
            var taxe: Double = 0
            successions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.personName == member.displayName {
                        taxe += inheritance.tax
                    }
                }
            }
            // on ne prend en compte que les droits de succession des adultes dans leur CashFlow commun
            if member is Adult {
                adultTaxes.perCategory[.succession]?.namedValues
                    .append((name  : member.displayName,
                             value : taxe))
            } else {
                // TODO: - créer un CashFlow pour chaque enfant
            }
            
            // succession des assurances vies
            taxe = 0
            lifeInsSuccessions.forEach { succession in
                succession.inheritances.forEach { inheritance in
                    if inheritance.personName == member.displayName {
                        taxe += inheritance.tax
                    }
                }
            }
            // on ne prend en compte que les droits de succession des adultes dans leur CashFlow commun
            if member is Adult {
                adultTaxes.perCategory[.liSuccession]?.namedValues
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
                                   with patrimoine : Patrimoin,
                                   using model     : Model) {
        // FIXME: - en fait il faudrait traiter les sucessions en séquences: calcul taxe => transmission puis calcul tax => transmission
        // identification des personnes décédées dans l'année
        let decedents = family.deceasedAdults(during: year)
        
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
                                                       atEndOf : year,
                                                       using   : model)
            successions.append(succession)
            
            // calculer les droits de transmission assurances vies
            let lifeInsuranceSuccessionManager = LifeInsuranceSuccessionManager()
            let liSuccession =
                lifeInsuranceSuccessionManager.lifeInsuraceSuccession(in      : patrimoine,
                                                                      of      : decedent,
                                                                      atEndOf : year,
                                                                      using   : model)
            lifeInsSuccessions.append(liSuccession)
            
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
