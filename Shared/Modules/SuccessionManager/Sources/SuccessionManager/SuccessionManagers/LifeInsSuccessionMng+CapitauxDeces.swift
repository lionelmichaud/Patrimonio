//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 29/10/2021.
//

import Foundation
import AssetsModel
import Ownership

// MARK: - Calcul des capitaux décès d'assurance vie

extension LifeInsuranceSuccessionManager {
    
    /// Calcule, pour chaque héritier `spouseName` et `childrenName` d'un défunt nommé `decedentName`,
    /// le montant des capitaux décès  TAXABLES reçus d'un ensemble d'assurances vie `invests`;
    ///
    /// L'usufruit rejoint la nue-propriété en franchise d'impôt et est donc exclue de la base taxable.
    ///
    /// - Warning: Cas non traités
    ///   - capital de l'assurance vie démembré et le défunt est nue-propriétaire (la NP devrait rejoindre l'UF)
    ///   - capital de l'assurance vie non démembré et co-détenu en PP par plusieurs personnes
    ///
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - invests: ensemble d'assurances vie
    ///   - spouseName: nom du conjoint du défunt
    ///   - childrenName: nom des enfants du défunt
    ///   - verbose: sorties console
    /// - Returns: [nom héritier : montant des capitaux décès reçus]
    func capitauxDecesTaxablesParPersonne(of decedentName : String,
                                          with invests    : [FinancialEnvelopP],
                                          spouseName      : String?,
                                          childrenName    : [String]?,
                                          verbose         : Bool = false) -> NameValueDico {
        var capitauxDeces : NameValueDico = [:]
        
        // pour chaque assurance vie
        invests.forEach { invest in
            capitauxDeces.merge(capitauxDecesTaxablesParPersonneParAssurance(of           : decedentName,
                                                                             spouseName   : spouseName,
                                                                             childrenName : childrenName,
                                                                             for          : invest,
                                                                             verbose      : verbose),
                                uniquingKeysWith: { $0 + $1 })
            
        }
        return capitauxDeces
    }
    
    /// Calcule, pour chaque héritier `spouseName` et `childrenName` d'un défunt nommé `decedentName`,
    /// le montant des capitaux décès  TAXABLES reçus d'une assurance vie `invest`;
    /// pour un décès survenu pendant l'année `year`
    ///
    /// L'usufruit rejoint la nue-propriété en franchise d'impôt et est donc exclue de la base taxable.
    ///
    /// - Warning: Cas non traités
    ///   - capital de l'assurance vie démembré et le défunt est nue-propriétaire (la NP devrait rejoindre l'UF)
    ///   - capital de l'assurance vie non démembré et co-détenu en PP par plusieurs personnes
    ///
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - spouseName: nom du conjoint du défunt
    ///   - childrenName: nom des enfants du défunt
    ///   - invest: une assurances vie
    ///   - verbose: sorties console
    /// - Returns: [nom héritier : montant des capitaux décès reçus]
    func capitauxDecesTaxablesParPersonneParAssurance(of decedentName  : String,
                                                      spouseName       : String?,
                                                      childrenName     : [String]?,
                                                      for invest       : FinancialEnvelopP,
                                                      verbose          : Bool = false) -> NameValueDico {
        guard invest.clause != nil else { return [:] }
        
        // on a affaire à une assurance vie
        // masse successorale pour cet investissement
        let ownedValueDecedent = invest.ownedValue(by                : decedentName,
                                                   atEndOf           : year,
                                                   evaluationContext : .lifeInsuranceSuccession)
        guard ownedValueDecedent > 0 else { return [:] }
        
        if invest.ownership.isDismembered {
            return dismemberedLifeInsCapitauxDecesTaxables(of      : decedentName,
                                                           for     : invest,
                                                           verbose : verbose)
        } else {
            return undismemberedLifeInsCapitauxDecesTaxables(of    : decedentName,
                                                      spouseName   : spouseName,
                                                      childrenName : childrenName,
                                                      for          : invest,
                                                      verbose      : verbose)
        }
    }
    
    /// Calcule, pour chaque héritier d'un défunt nommé `decedentName`,
    /// les bases taxables `massesSuccession` d'une assurance vie `invest` DEMEMBRÉE;
    /// pour un décès survenu pendant l'année `year`
    ///
    /// L'usufruit rejoint la nue-propriété en franchise d'impôt et est donc exclue de la base taxable.
    ///
    /// - Warning: Cas non traités
    ///  - capital de l'assurance vie démembré et le défunt est nue-propriétaire (la NP devrait rejoindre l'UF)
    ///
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - invest: une assurances vie
    ///   - verbose: sorties console
    func dismemberedLifeInsCapitauxDecesTaxables(of decedentName : String,
                                                 for invest      : FinancialEnvelopP,
                                                 verbose         : Bool = false) -> NameValueDico {
        if invest.ownership.hasAnUsufructOwner(named: decedentName) {
            // le capital de l'assurane vie est démembré
            // le défunt est usufruitier
            // l'usufruit rejoint la nue-propriété sans taxe
            return [:]
        }
        
        if invest.ownership.hasABareOwner(named: decedentName) {
            // le capital de l'assurane vie est démembré
            // le défunt est un nue-propriétaire
            // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire (la NP rejoint l'UF)
            fatalError("lifeInsuraceSuccession: cas non traité (capital démembré et le défunt est nue-propriétaire)")
        }

        // le défunt n'est ni usufruitier ni nue-propriétaire de l'AV
        return [:]
    }
    
    /// Calcule, pour chaque héritier d'un défunt nommé `decedentName`,
    /// les bases taxables `massesSuccession` d'une assurance vie `invest` NON DEMEMBRÉE;
    /// pour un décès survenu pendant l'année `year`
    ///
    /// L'usufruit rejoint la nue-propriété en franchise d'impôt et est donc exclue de la base taxable.
    ///
    /// - Warning: Cas non traités
    ///  - capital de l'assurance vie démembré et le défunt est nue-propriétaire (la NP devrait rejoindre l'UF)
    ///
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - spouseName: nom du conjoint du défunt
    ///   - childrenName: nom des enfants du défunt
    ///   - invest: une assurances vie
    ///   - verbose: sorties console
    func undismemberedLifeInsCapitauxDecesTaxables(of decedentName : String,
                                                   spouseName      : String?,
                                                   childrenName    : [String]?,
                                                   for invest      : FinancialEnvelopP,
                                                   verbose         : Bool = false) -> NameValueDico {
        guard var clause = invest.clause else { return [:]}
        
        let ownedValuesBeforeTranmission =
            invest.ownedValues(atEndOf           : year - 1,
                               evaluationContext : .lifeInsuranceSuccession)
        
        var _invest = invest
        // simuler localement le transfert de propriété
        try! _invest.ownership.transferUndismemberedLifeInsurance(of           : decedentName,
                                                                  spouseName   : spouseName,
                                                                  childrenName : childrenName,
                                                                  accordingTo  : &clause)
        let ownedValuesAfterTranmission =
            _invest.ownedValues(atEndOf           : year - 1,
                                evaluationContext : .lifeInsuranceSuccession)
        
        // faire la différence après / avant pour connaître les capitaux décès hérités
        var capitauxDeces : NameValueDico = [:]
        ownedValuesAfterTranmission.forEach { (newOwnerName, newOwnedvalue) in
            // différence après - avant
            let oldOwnedValue = ownedValuesBeforeTranmission[newOwnerName] ?? 0.0
            
            // s'il y a enrichissement
            if newOwnedvalue > oldOwnedValue {
                capitauxDeces[newOwnerName] = newOwnedvalue
            }
        }
        return capitauxDeces
    }
    
}
