//
//  LifeInsuranceSuccessionManager.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import FiscalModel

struct LifeInsuranceSuccessionManager {
    /// Calcule la masse totale d'assurance vie de la succession d'une personne.
    ///
    /// - Note:Inclue toutes les AV y.c. celles qui sont démembrées et détenues en UF donc non taxables.
    ///
    /// - WARNING: Prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
    /// - Parameters:
    ///   - patrimoine: le patrimoine de la famille
    ///   - decedent: défunt
    ///   - year: année du décès - 1
    /// - Returns: masse totale d'assurance vie de la succession d'une personne
    fileprivate func lifeInsuraceInheritanceValue(in patrimoine : Patrimoin,
                                                  of decedent   : Person,
                                                  atEndOf year  : Int) -> Double {
        var taxable                                             : Double = 0
        patrimoine.forEachOwnable { ownable in
            taxable += ownable.ownedValue(by               : decedent.displayName,
                                          atEndOf          : year,
                                          evaluationMethod : .lifeInsuranceSuccession)
        }
        return taxable
    }
    
    /// Calcule, pour chaque héritier, la base taxable d'une assurance vie
    ///
    /// L'usufruit rejoint la nue-propriété en franchise d'impôt et est donc exclue de la base taxable.
    ///
    /// - Parameters:
    ///   - decedent: défunt
    ///   - year: année du décès - 1
    ///   - invest: l'investissemment à analyser
    ///   - massesSuccession: (héritier, base taxable)
    fileprivate func lifeInsuranceSuccessionMasses(of decedent      : Person,
                                                   for invest       : FinancialEnvelop,
                                                   atEndOf year     : Int,
                                                   massesSuccession : inout [String : Double]) {
        var _invest = invest
        if let clause = invest.clause {
            // on a affaire à une assurance vie
            // masse successorale pour cet investissement
            let masseDecedent = invest.ownedValue(by               : decedent.displayName,
                                                  atEndOf          : year,
                                                  evaluationMethod : .lifeInsuranceSuccession)
            guard masseDecedent > 0 else { return }
            
            if invest.ownership.hasAnUsufructOwner(named: decedent.displayName) {
                // le capital de l'assurane vie est démembré
                // le défunt est usufruitier
                // l'usufruit rejoint la nue-propriété sans taxe
                ()
            }
            if invest.ownership.hasABareOwner(named: decedent.displayName) {
                // le capital de l'assurane vie est démembré
                // le défunt est un nue-propriétaire
                // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire
                fatalError("lifeInsuraceSuccession: cas non traité (capital démembré et le défunt est nue-propriétaire)")
            }
            
            // le défunt est-il un des PP du capital de l'assurance vie ?
            if invest.ownership.hasAFullOwner(named: decedent.displayName) {
                // le capital de l'assurance vie n'est pas démembré
                // le seul PP ?
                if invest.ownership.fullOwners.count == 1 {
                    if clause.isDismembered {
                        // la clause bénéficiaire de l'assurance vie est démembrée
                        // simuler localement le transfert de propriété pour connaître les masses héritées
                        _invest.ownership.transferLifeInsuranceUsufructAndBareOwnership(clause: clause)
                        
                    } else {
                        // la clause bénéficiaire de l'assurance vie n'est pas démembrée
                        // simuler localement le transfert de propriété pour connaître les masses héritées
                        _invest.ownership.transferLifeInsuranceFullOwnership(clause: clause)
                    }
                    let ownedValues = _invest.ownedValues(atEndOf: year, evaluationMethod: .lifeInsuranceSuccession)
                    ownedValues.forEach { (name, value) in
                        if massesSuccession[name] != nil {
                            // incrémenter
                            massesSuccession[name]! += value
                        } else {
                            massesSuccession[name] = value
                        }
                    }
                    
                } else {
                    // TODO: - traiter le cas où le capital est co-détenu en PP par plusieurs personnes
                    fatalError("lifeInsuraceSuccession: cas non traité (capital co-détenu en PP par plusieurs personnes)")
                }
            } // sinon on ne fait rien car le défunt ne possède aucun droit sur le bien
        }
    }
    
    /// Calcule la transmission d'assurance vie d'un défunt et retourne une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - decedent: défunt
    ///   - year: année du décès
    /// - Returns: Succession du défunt incluant la table des héritages et droits de succession pour chaque héritier
    func lifeInsuraceSuccession(in patrimoine : Patrimoin,
                                of decedent   : Person,
                                atEndOf year  : Int) -> Succession {
        var inheritances     : [Inheritance]     = []
        var massesSuccession : [String : Double] = [:]
        
        guard let family = Patrimoin.family else {
            return Succession(kind         : .lifeInsurance,
                              yearOfDeath  : year,
                              decedent     : decedent,
                              taxableValue : 0,
                              inheritances : [])
        }
        
        // calculer la masse d'assurance vie de la succession (y.c. celle détenue uniquement en UF)
        // WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
        //        let totalInheritanceValue = lifeInsuraceInheritanceValue(in      : patrimoine,
        //                                                                 of      : decedent,
        //                                                                 atEndOf : year - 1)
        //        print("\n  Masse d'assurance vie détenue = \(totalInheritanceValue.rounded())")
        
        // pour chaque assurance vie
        patrimoine.assets.freeInvests.items.forEach { invest in
            lifeInsuranceSuccessionMasses(of               : decedent,
                                          for              : invest,
                                          atEndOf          : year - 1,
                                          massesSuccession : &massesSuccession)
        }
        patrimoine.assets.periodicInvests.items.forEach { invest in
            lifeInsuranceSuccessionMasses(of               : decedent,
                                          for              : invest,
                                          atEndOf          : year - 1,
                                          massesSuccession : &massesSuccession)
        }
        
        // calcul de la masse totale taxable
        let totalTaxableInheritanceValue = massesSuccession.values.sum()
        
        // pour chaque membre de la famille autre que le défunt
        for member in family.members.items where member != decedent {
            if let masse = massesSuccession[member.displayName] {
                var heritage = (netAmount: 0.0, taxe: 0.0)
                if member is Adult {
                    // le conjoint
                    heritage = Fiscal.model.lifeInsuranceInheritance.heritageToConjoint(partSuccession: masse)
                } else {
                    // les enfants
                    heritage = try! Fiscal.model.lifeInsuranceInheritance.heritageOfChild(partSuccession: masse)
                }
                //                print("  Part d'héritage de \(member.displayName) = \(masse.rounded()) (\((masse/totalTaxableInheritanceValue*100.0).rounded()) %)")
                //                print("    Taxe = \(heritage.taxe.rounded())")
                inheritances.append(Inheritance(person  : member,
                                                percent : masse / totalTaxableInheritanceValue,
                                                brut    : masse,
                                                net     : heritage.netAmount,
                                                tax     : heritage.taxe))
            }
        }
        
        //        print("  Masse totale = ", totalTaxableInheritanceValue.rounded())
        //        print("  Taxe totale  = ", inheritances.sum(for: \.tax).rounded())
        return Succession(kind         : .lifeInsurance,
                          yearOfDeath  : year,
                          decedent     : decedent,
                          taxableValue : totalTaxableInheritanceValue,
                          inheritances : inheritances)
    }
}
