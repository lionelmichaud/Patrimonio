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
    /// le montant des capitaux décès  TAXABLES et RECUS en CASH d'un ensemble d'assurances vie `invests`
    /// et le montant des créances de restitution
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
     received : NameValueDico,
     creances : CreanceDeRestituationDico) {
        var capitauxDeces = (taxable  : NameValueDico(),
                             received : NameValueDico(),
                             creances : CreanceDeRestituationDico())
        
        // pour chaque assurance vie
        invests.forEach { invest in
            let _capitauxDecesParPersonneParAssurance =
                capitauxDecesParPersonneParAssurance(of      : decedentName,
                                                     for     : invest,
                                                     verbose : verbose)
            capitauxDeces.taxable.merge(_capitauxDecesParPersonneParAssurance.taxable,
                                        uniquingKeysWith: { $0 + $1 })
            capitauxDeces.received.merge(_capitauxDecesParPersonneParAssurance.received,
                                         uniquingKeysWith: { $0 + $1 })
            capitauxDeces.creances.merge(_capitauxDecesParPersonneParAssurance.creances,
                                         uniquingKeysWith: {
                                            $0.merging($1,
                                                       uniquingKeysWith: { $0 + $1 })
                                         })
        }
        if verbose {
            print(
                """
                Capitaux décès totaux : ")
                   Taxable       : \(String(describing: capitauxDeces.taxable))
                   Reçu en cash  : \(String(describing: capitauxDeces.received))
                   Créances rest : \(String(describing: capitauxDeces.creances))
                """)
        }
        return capitauxDeces
    }
    
    /// Calcule, pour chaque héritier `spouseName` et `childrenName` d'un défunt nommé `decedentName`,
    /// le montant des capitaux décès  TAXABLES et RECUS en CASH d'une assurance vie `invest`;
    /// et le montant des créances de restitution
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
     received : NameValueDico,
     creances : CreanceDeRestituationDico) {
        
        guard invest.isLifeInsurance else {
            return (taxable: [:], received: [:], creances: [:])
        }
        
        // on a affaire à une assurance vie
        // masse successorale pour cet investissement
        let ownedValueDecedent = invest.ownedValue(by                : decedentName,
                                                   atEndOf           : year - 1,
                                                   evaluationContext : .lifeInsuranceSuccession)
        guard ownedValueDecedent > 0 else {
            return (taxable: [:], received: [:], creances: [:])
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
    /// et le montant des créances de restitution
    /// pour une assurance vie `invest` DEMEMBRÉE;
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
     received : NameValueDico,
     creances : CreanceDeRestituationDico) {
        
        guard invest.isLifeInsurance else {
            return (taxable: [:], received: [:], creances: [:])
        }
        guard invest.ownership.isDismembered else {
            fatalError("Le bien doit être démembré")
        }
        if invest.ownership.hasAnUsufructOwner(named: decedentName) {
            // le capital de l'assurane vie est démembré
            // le défunt est usufruitier
            // l'usufruit rejoint la nue-propriété sans taxe
            if verbose {
                print("Le capital de '\(invest.name)' est démembré : l'usufruit rejoint la nu-propriété sans versement de cash, non taxable")
            }
            return (taxable: [:], received: [:], creances: [:])
        }
        
        if invest.ownership.hasABareOwner(named: decedentName) {
            // le capital de l'assurane vie est démembré
            // le défunt est un nue-propriétaire
            // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire (la NP rejoint l'UF)
            fatalError("cas non traité (capital démembré et le défunt est nue-propriétaire)")
        }
        
        // le défunt n'est ni usufruitier ni nue-propriétaire de l'AV
        return (taxable: [:], received: [:], creances: [:])
    }
    
    /// Calcule, pour chaque héritier d'un défunt nommé `decedentName`,
    /// le valeur taxable `taxable` et le montant de l'éventuel versement reçu en cash `received`
    /// et le montant des créances de restitution
    /// pour une assurance vie `invest` NON DEMEMBRÉE;
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
     received : NameValueDico,
     creances : CreanceDeRestituationDico) {
        
        guard let clause = invest.clause else {
            // le bien n'est pas une assurance vie
            return (taxable: [:], received: [:], creances: [:])
        }
        guard clause.isValid else {
            customLog.log(level: .fault, "La clause bénéficiaire n'est pas valide \(clause, privacy: .public)")
            fatalError("La clause bénéficiaire n'est pas valide")
        }
        guard !invest.ownership.isDismembered else {
            customLog.log(level: .fault, "Le bien ne doit pas être démembré")
            fatalError("Le bien ne doit pas être démembré)")
        }
        guard invest.ownership.hasAFullOwner(named: decedentName) else {
            // le défunt n'a aucun droit de propriété sur le bien
            return (taxable: [:], received: [:], creances: [:])
        }
        
        // masse successorale
        let ownedValueDecedent = invest.ownedValue(by                : decedentName,
                                                   atEndOf           : year - 1,
                                                   evaluationContext : .lifeInsuranceSuccession)
        
        var capitauxDeces = (taxable  : NameValueDico(),
                             received : NameValueDico(),
                             creances : CreanceDeRestituationDico())
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
            
            // Calculer et mémoriser les créances de restitutions de l'UF envers les NP
            var creances = NameValueDico()
            clause.bareRecipients.forEach { creancier in
                creances[creancier] = ownedValueDecedent / clause.bareRecipients.count.double()
            }
            capitauxDeces.creances[clause.usufructRecipient] = creances
            
        } else {
            // Clause non démembrée
            // versée en cash au donataires désignés dans la clause bénéficiaire
            // taxable
            clause.fullRecipients.forEach { recipientOwner in
                let recipientShare = recipientOwner.fraction * ownedValueDecedent / 100.0
                capitauxDeces.taxable[recipientOwner.name]  = recipientShare
                capitauxDeces.received[recipientOwner.name] = recipientShare
            }
        }

        if verbose {
            print(
                """
                Capitaux décès issus de \(invest.name) : ")
                   Taxable       : \(String(describing: capitauxDeces.taxable))
                   Reçu en cash  : \(String(describing: capitauxDeces.received))
                   Créances rest : \(String(describing: capitauxDeces.creances))
                """)
        }
        return capitauxDeces
    }
}
