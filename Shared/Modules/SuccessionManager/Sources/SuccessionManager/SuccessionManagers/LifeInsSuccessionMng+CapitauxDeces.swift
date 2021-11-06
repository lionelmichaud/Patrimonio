//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 29/10/2021.
//

import Foundation
import os
import AssetsModel
import Ownership
import FiscalModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine",
                               category: "Model.LifeInsuranceSuccessionManager")

// MARK: - Calcul des capitaux décès d'assurance vie

extension LifeInsuranceSuccessionManager {
    
    /// Calcule, pour chaque héritier `spouseName` et `childrenName` d'un défunt nommé `decedentName`,
    /// le montant des capitaux décès  TAXABLES et RECUS en CASH d'un ensemble d'assurances vie `invests`;
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
    ///   - verbose: sorties console
    /// - Returns: ([Nom héritier : valeur taxable], [Nom héritier : montant reçu en cash])
    func capitauxDecesTaxableRecusParPersonne(of decedentName : String,
                                              with invests    : [FinancialEnvelopP],
                                              verbose         : Bool = false) ->
    (taxable  : NameValueDico,
     received : NameValueDico) {
        var capitauxTaxables : (taxable  : NameValueDico,
                                received : NameValueDico) = ([:], [:])
        
        // pour chaque assurance vie
        invests.forEach { invest in
            let _capitauxDecesParPersonneParAssurance =
                capitauxDecesParPersonneParAssurance(of      : decedentName,
                                                     for     : invest,
                                                     verbose : verbose)
            capitauxTaxables.taxable.merge(_capitauxDecesParPersonneParAssurance.taxable,
                                           uniquingKeysWith: { $0 + $1 })
            capitauxTaxables.received.merge(_capitauxDecesParPersonneParAssurance.received,
                                            uniquingKeysWith: { $0 + $1 })
        }
        if verbose {
            print("Capitaux décès totaux taxables : ")
            print("  ", String(describing: capitauxTaxables))
        }
        return capitauxTaxables
    }
    
    /// Calcule, pour chaque héritier `spouseName` et `childrenName` d'un défunt nommé `decedentName`,
    /// le montant des capitaux décès  TAXABLES et RECUS en CASH d'une assurance vie `invest`;
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
    ///   - invest: une assurances vie
    ///   - verbose: sorties console
    /// - Returns: ([Nom héritier : valeur taxable], [Nom héritier : montant reçu en cash])
    func capitauxDecesParPersonneParAssurance(of decedentName : String,
                                              for invest      : FinancialEnvelopP,
                                              verbose         : Bool = false) ->
    (taxable  : NameValueDico,
     received : NameValueDico) {
        
        guard invest.isLifeInsurance else {
            return (taxable: [:], received: [:])
        }
        
        // on a affaire à une assurance vie
        // masse successorale pour cet investissement
        let ownedValueDecedent = invest.ownedValue(by                : decedentName,
                                                   atEndOf           : year - 1,
                                                   evaluationContext : .lifeInsuranceSuccession)
        guard ownedValueDecedent > 0 else {
            return (taxable: [:], received: [:])
        }
        
        if invest.ownership.isDismembered {
            return capitauxDecesAvDismembered(of      : decedentName,
                                              for     : invest,
                                              verbose : verbose)
        } else {
            return capitauxDecesAvUndismembered(of      : decedentName,
                                                for     : invest,
                                                verbose : verbose)
        }
    }
    
    /// Calcule, pour chaque héritier d'un défunt nommé `decedentName`,
    /// le valeur taxable `taxable` et le montant de l'éventuel versement reçu en cash `received`
    /// pour une assurance vie `invest` DEMEMBRÉE;
    /// pour un décès survenu pendant l'année `year`
    ///
    /// L'usufruit rejoint la nue-propriété en franchise d'impôt et est donc exclue de la base taxable.
    ///
    /// - Note: La clause bénéficiaire ne peut pas être démembrée
    /// - Warning: Cas non traités
    ///  - capital de l'assurance vie démembré et le défunt est nue-propriétaire (la NP devrait rejoindre l'UF)
    ///
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - invest: une assurances vie
    ///   - verbose: sorties console
    /// - Returns: ([Nom héritier : valeur taxable], [Nom héritier : montant reçu en cash])
    func capitauxDecesAvDismembered(of decedentName : String,
                                    for invest      : FinancialEnvelopP,
                                    verbose         : Bool = false) ->
    (taxable  : NameValueDico,
     received : NameValueDico) {
        
        guard let clause = invest.clause else {
            return (taxable: [:], received: [:])
        }
        guard !clause.isDismembered else {
            fatalError("la clause ne doit pas être démembrée")
        }
        guard invest.ownership.isDismembered else {
            fatalError("Le bien doit être démembré)")
        }
        if invest.ownership.hasAnUsufructOwner(named: decedentName) {
            // le capital de l'assurane vie est démembré
            // le défunt est usufruitier
            // l'usufruit rejoint la nue-propriété sans taxe
            if verbose {
                print("Le capital de '\(invest.name)' est démembré : l'usufruit rejoint la nu-propriété sans versement de cash, non taxable")
            }
            return (taxable: [:], received: [:])
        }
        
        if invest.ownership.hasABareOwner(named: decedentName) {
            // le capital de l'assurane vie est démembré
            // le défunt est un nue-propriétaire
            // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire (la NP rejoint l'UF)
            fatalError("cas non traité (capital démembré et le défunt est nue-propriétaire)")
        }
        
        // le défunt n'est ni usufruitier ni nue-propriétaire de l'AV
        return (taxable: [:], received: [:])
    }
    
    /// Calcule, pour chaque héritier d'un défunt nommé `decedentName`,
    /// le valeur taxable `taxable` et le montant de l'éventuel versement reçu en cash `received`
    /// pour une assurance vie `invest` NON DEMEMBRÉE;
    /// pour un décès survenu pendant l'année `year`
    ///
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - spouseName: nom du conjoint du défunt
    ///   - childrenName: nom des enfants du défunt
    ///   - invest: une assurances vie
    ///   - verbose: sorties console
    /// - Returns: ([Nom héritier : valeur taxable], [Nom héritier : montant reçu en cash])
    func capitauxDecesAvUndismembered(of decedentName : String,
                                      for invest      : FinancialEnvelopP,
                                      verbose         : Bool = false) ->
    (taxable  : NameValueDico,
     received : NameValueDico) {
        
        guard let clause = invest.clause else {
            // le bien n'est pas une assurance vie
            return (taxable: [:], received: [:])
        }
        guard clause.isValid else {
            customLog.log(level: .fault, "La clause bénéficiaire n'est pas valide \(clause, privacy: .public)")
            fatalError("La clause bénéficiaire n'est pas valide")
        }
        guard !invest.ownership.isDismembered else {
            fatalError("Le bien ne doit pas être démembré)")
        }
        guard invest.ownership.hasAFullOwner(named: decedentName) else {
            // le défunt n'a aucun droit de propriété sur le bien
            return (taxable: [:], received: [:])
        }
        
        // masse successorale
        let ownedValueDecedent = invest.ownedValue(by                : decedentName,
                                                   atEndOf           : year - 1,
                                                   evaluationContext : .lifeInsuranceSuccession)
        
        var capitauxDeces : (taxable  : NameValueDico,
                             received : NameValueDico) = ([:], [:])
        if clause.isDismembered {
            // Clause démembrée
            // le donataire usufruitier se voit crédité de la masse successorale totale: quasi-usufruit
            capitauxDeces.received[clause.usufructRecipient]  = ownedValueDecedent
            
            // les valeurs taxables sont celles du démembrement
            //   calcul de répartition des % de valeur démembrée
            let usufructRecipientAge = family.ageOf(clause.usufructRecipient, year)
            let demembrement = try! fiscalModel.demembrement.demembrement(of              : ownedValueDecedent,
                                                                          usufructuaryAge : usufructRecipientAge)
            //  répartition
            capitauxDeces.taxable[clause.usufructRecipient]  = demembrement.usufructValue
            clause.bareRecipients.forEach { recipient in
                capitauxDeces.taxable[recipient] = demembrement.bareValue / clause.bareRecipients.count.double()
            }
            
        } else {
            // Clause non démembrée
            // versée en cash au donataires désignés dans la caluse bénéficiaire
            // taxable
            clause.fullRecipients.forEach { recipientOwner in
                let recipientShare = recipientOwner.fraction * ownedValueDecedent / 100.0
                capitauxDeces.taxable[recipientOwner.name]  = recipientShare
                capitauxDeces.received[recipientOwner.name] = recipientShare
            }
        }

        if verbose {
            print("Capitaux décès issus de \(invest.name): ")
            print("  Taxable      : ", String(describing: capitauxDeces.taxable))
            print("  Reçu en cash : ", String(describing: capitauxDeces.received))
        }
        return capitauxDeces
    }
    
}
