//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 29/10/2021.
//

import Foundation
import Ownership
import NamedValue
import AssetsModel

// MARK: - Calcul des abattements individuels sur les capitaux décès d'assurance vie

extension LifeInsuranceSuccessionManager {
    
    /// Calcule, pour chaque héritier `spouseName` et `childrenName` d'un défunt nommé `decedentName`,
    /// le montant de l'abattement par héritier sur les capitaux décès
    /// - Parameters:
    ///   - invests: ensemble d'assurances vie
    ///   - spouseName: nom du conjoint du défunt
    ///   - childrenName: nom des enfants du défunt
    ///   - verbose: sorties console
    /// - Returns: [nom héritier : fraction de l'abattement maximum [0;1] ]
    func abattementsParPersonne(for invests  : [FinancialEnvelopP],
                                spouseName   : String?,
                                childrenName : [String]?,
                                verbose      : Bool = false) -> NameValueDico {
        // calculer les montants des abattements par couple UF / NP
        // pour les donataires d'AV avec clause démembrée
        let setAbatCoupleUFNP = abattementsParCouple(for     : invests,
                                                     verbose : verbose)
        // en déduire l'abattement par personne
        var abattementsDico = NameValueDico()
        setAbatCoupleUFNP.forEach { couple in
            let uf = couple.UF
            if abattementsDico[uf.name] == nil {
                abattementsDico[uf.name] = uf.value
            } else {
                abattementsDico[uf.name] = min(uf.value + abattementsDico[uf.name]!, 1.0)
            }
            let np = couple.NP
            if abattementsDico[np.name] == nil {
                abattementsDico[np.name] = np.value
            } else {
                abattementsDico[np.name] = min(np.value + abattementsDico[np.name]!, 1.0)
            }
        }
        if verbose {
            print("Abattements des héritiers participants à des démembrements:")
            print(String(describing: abattementsDico))
        }
        
        // les autres bénéficient de 100% d'abattement par personne
        childrenName?.forEach { name in
            if abattementsDico[name] == nil {
                abattementsDico[name] = 1.0
            }
        }
        if spouseName != nil && abattementsDico[spouseName!] == nil {
            abattementsDico[spouseName!] = 1.0
        }
        if verbose {
            print("Abattements des héritiers:")
            print(String(describing: abattementsDico))
        }
        
        return abattementsDico
    }
    
    /// Calcule, pour chaque héritier `spouseName` et `childrenName` d'un défunt nommé `decedentName`,
    /// le montant de l'abattement par héritier sur les capitaux décès reçus d'AV avec clause démembrée
    /// - Parameters:
    ///   - invests: ensemble d'assurances vie
    ///   - verbose: sorties console
    /// - Returns: set de couples (UF, NP)
    func abattementsParCouple(for invests : [FinancialEnvelopP],
                              verbose     : Bool = false) -> SetAbatCoupleUFNP {
        var setAbatCoupleUFNP = SetAbatCoupleUFNP()
        
        // pour chaque assurance vie
        invests.forEach { invest in
            if invest.isOwnedBySomebody {
                setAbatCoupleUFNP.formUnion(abattementsParAssurance(for     : invest,
                                                                    verbose : verbose))
            }
        }
        if verbose {
            print(setAbatCoupleUFNP)
        }
        return setAbatCoupleUFNP
    }
    
    func abattementsParAssurance(for invest : FinancialEnvelopP,
                                 verbose    : Bool = false) -> SetAbatCoupleUFNP {
        guard let clause = invest.clause else {
            return SetAbatCoupleUFNP()
        }
        
        guard clause.isDismembered else {
            return SetAbatCoupleUFNP()
        }
        
        // on a affaire à une assurance vie avec clause démembrée
        var set = SetAbatCoupleUFNP()
        let ufName = clause.usufructRecipient
        let demembrement = try! fiscalModel.demembrement
            .demembrement(of: 1,
                          usufructuaryAge: family.ageOf(ufName, year))
        let uf = NamedValue(name: ufName, value: demembrement.usufructValue)
        clause.bareRecipients.forEach { br in
            let np = NamedValue(name: br, value: demembrement.bareValue)
            let coupleUFNP = CoupleUFNP(UF: uf, NP: np)
            set.insert(coupleUFNP)
        }
        if verbose {
            print(set)
        }
        return set
    }

}
