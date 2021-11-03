//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 01/11/2021.
//

import Foundation
import NamedValue
import Ownership
import AssetsModel
import PatrimoineModel

// MARK: - Prélèvements à la source des taxes de transmission sur les capitaux décès d'assurance vie

extension LifeInsuranceSuccessionManager {
    
    /// Prélever à la source les taxes de transmission sur les capitaux décès d'assurance vie
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - patrimoine: patrimoine
    ///   - spouseName: nom du conjoint du défunt
    ///   - childrenName: nom des enfants du défunt
    func removeTransmissionTaxes(of decedentName : String,
                                 with patrimoine : Patrimoin,
                                 spouseName      : String?,
                                 childrenName    : [String]?,
                                 verbose         : Bool = false) {
        // calculer le montant de l'abattement de chaque héritier
        var financialEnvelops: [FinancialEnvelopP] =
            patrimoine.assets.freeInvests.items + patrimoine.assets.periodicInvests.items
        
        var abattementsDico =
            abattementsParPersonne(of           : decedentName,
                                   with         : financialEnvelops,
                                   spouseName   : spouseName,
                                   childrenName : childrenName,
                                   verbose      : verbose)
        
        // commencer par les AV à clause non démembrée
        financialEnvelops.sort(by: { !$0.ownership.isDismembered && $1.ownership.isDismembered })
        
        // pour chaque AV non démembrées (pour les démembrées, la transmission de l'UF n'est pas taxée)
        for invest in financialEnvelops where invest.isLifeInsurance && !invest.ownership.isDismembered {
            // prélever les taxes à la source
            removeTransmissionTaxes(from            : invest,
                                    withAbattements : &abattementsDico,
                                    decedentName    : decedentName,
                                    spouseName      : spouseName,
                                    childrenName    : childrenName,
                                    verbose         : verbose)
        }
    }
    
    func removeTransmissionTaxes(from invest                 : FinancialEnvelopP,
                                 withAbattements abattements : inout NameValueDico,
                                 decedentName                : String,
                                 spouseName                  : String?,
                                 childrenName                : [String]?,
                                 verbose                     : Bool = false) {
        // calculer les capitaux décès reçus par chaque bénéficiaire
        let capitauxDeces =
            capitauxDecesTaxablesParPersonneParAssurance(of           : decedentName,
                                                         spouseName   : spouseName,
                                                         childrenName : childrenName,
                                                         for          : invest,
                                                         verbose      : verbose)
        // prélever les taxes à la source
        if invest.clause!.isDismembered {
            removeTransmissionTaxesClauseDismembered()
        } else {
            removeTransmissionTaxesClauseUndismembered()
        }
    }
    
    func removeTransmissionTaxesClauseDismembered() {
        
    }
    func removeTransmissionTaxesClauseUndismembered() {
        
    }
}
