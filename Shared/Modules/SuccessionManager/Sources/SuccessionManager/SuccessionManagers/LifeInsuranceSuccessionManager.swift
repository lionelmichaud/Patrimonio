//
//  LifeInsuranceSuccessionManager.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import Ownership
import AssetsModel
import Succession
import FiscalModel
import PersonModel
import PatrimoineModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.LifeInsuranceSuccessionManager")

struct LifeInsuranceSuccessionManager {

    // MARK: - Properties

    private var fiscalModel : Fiscal.Model
    private var family      : FamilyProviderP
    private var year        : Int

    // MARK: - Initializers

    public init(using fiscalModel : Fiscal.Model,
                atEndOf year      : Int) {
        guard let familyProvider = Patrimoin.familyProvider else {
            customLog.log(level: .fault, "Patrimoin.familyProvider non initialisé")
            fatalError()
        }
        self.fiscalModel = fiscalModel
        self.family      = familyProvider
        self.year        = year
    }

    // MARK: - Methods

    /// Calcule la transmission d'assurance vie d'un `patrimoine` au décès de `decedentName` et retourne
    /// une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - decedentName: nom du défunt
    ///   - year: année du décès
    ///   - fiscalModel: modèle fiscal à utiliser
    /// - Returns: Succession du défunt incluant la table des héritages et droits de succession pour chaque héritier
    func lifeInsuranceSuccession(of decedentName   : String,
                                 with patrimoine   : Patrimoin,
                                 spouseName        : String?,
                                 childrenName      : [String]?) -> Succession {
        var inheritances     : [Inheritance]     = []
        var massesSuccession : NameValueDico = [:]
        
        guard let family = Patrimoin.familyProvider else {
            return Succession(kind         : .lifeInsurance,
                              yearOfDeath  : year,
                              decedentName : decedentName,
                              taxableValue : 0,
                              inheritances : [])
        }
        
        // pour chaque assurance vie
        patrimoine.assets
            .freeInvests
            .items
            .forEach { invest in
                lifeInsuranceSuccessionMasses(of               : decedentName,
                                              spouseName       : spouseName,
                                              childrenName     : childrenName,
                                              for              : invest,
                                              massesSuccession : &massesSuccession)
            }
        
        patrimoine.assets
            .periodicInvests
            .items
            .forEach { invest in
                lifeInsuranceSuccessionMasses(of               : decedentName,
                                              spouseName       : spouseName,
                                              childrenName     : childrenName,
                                              for              : invest,
                                              massesSuccession : &massesSuccession)
            }
        
        // calcul de la masse totale taxable
        let totalTaxableInheritanceValue = massesSuccession.values.sum()
        
        // pour chaque membre de la famille autre que le défunt
        for member in family.members.items where member.displayName != decedentName {
            if let masse = massesSuccession[member.displayName] {
                var heritage = (netAmount: 0.0, taxe: 0.0)
                if member is Adult {
                    // le conjoint
                    heritage = fiscalModel.lifeInsuranceInheritance.heritageToConjoint(partSuccession: masse)
                } else {
                    // les enfants
                    heritage = try! fiscalModel.lifeInsuranceInheritance.heritageOfChild(partSuccession: masse)
                }
                //                print("  Part d'héritage de \(member.displayName) = \(masse.rounded()) (\((masse/totalTaxableInheritanceValue*100.0).rounded()) %)")
                //                print("    Taxe = \(heritage.taxe.rounded())")
                inheritances.append(Inheritance(personName : member.displayName,
                                                percent    : masse / totalTaxableInheritanceValue,
                                                brut       : masse,
                                                net        : heritage.netAmount,
                                                tax        : heritage.taxe))
            }
        }
        
        //        print("  Masse totale = ", totalTaxableInheritanceValue.rounded())
        //        print("  Taxe totale  = ", inheritances.sum(for: \.tax).rounded())
        return Succession(kind         : .lifeInsurance,
                          yearOfDeath  : year,
                          decedentName : decedentName,
                          taxableValue : totalTaxableInheritanceValue,
                          inheritances : inheritances)
    }

    /// Calcule, pour chaque héritier d'un défunt nommé `decedentName`,
    /// les bases taxables `massesSuccession` d'une assurance vie `invest`;
    /// pour un décès survenu pendant l'année `year`
    ///
    /// L'usufruit rejoint la nue-propriété en franchise d'impôt et est donc exclue de la base taxable.
    ///
    /// - Warning: Cas non traités
    ///   - capital de l'assurance vie démembré et le défunt est nue-propriétaire (la NP devrait rejoindre l'UF)
    ///   - capital de l'assurance vie non démembré et co-détenu en PP par plusieurs personnes
    ///
    /// - Parameters:
    ///   - decedent: défunt
    ///   - invest: l'investissemment à analyser
    ///   - year: année du décès - 1
    ///   - massesSuccession: (héritier, base taxable)
    fileprivate func lifeInsuranceSuccessionMasses
    (of decedentName  : String,
     spouseName       : String?,
     childrenName     : [String]?,
     for invest       : FinancialEnvelopP,
     massesSuccession : inout NameValueDico) {
        guard invest.clause != nil else { return }
        
        // on a affaire à une assurance vie
        // masse successorale pour cet investissement
        let masseDecedent = invest.ownedValue(by                : decedentName,
                                              atEndOf           : year,
                                              evaluationContext : .lifeInsuranceSuccession)
        guard masseDecedent > 0 else { return }
        
        if invest.ownership.isDismembered {
            dismemberedLifeInsuranceSuccessionMasses(of               : decedentName,
                                                     for              : invest,
                                                     massesSuccession : &massesSuccession)
        } else {
            undismemberedLifeInsuranceSuccessionMasses(of               : decedentName,
                                                       spouseName       : spouseName,
                                                       childrenName     : childrenName,
                                                       for              : invest,
                                                       massesSuccession : &massesSuccession)
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
    ///   - invest: l'investissemment à analyser
    ///   - year: année du décès - 1
    ///   - massesSuccession: (héritier, base taxable)
    fileprivate func dismemberedLifeInsuranceSuccessionMasses
    (of decedentName  : String,
     for invest       : FinancialEnvelopP,
     massesSuccession : inout NameValueDico) {
        if invest.ownership.hasAnUsufructOwner(named: decedentName) {
            // le capital de l'assurane vie est démembré
            // le défunt est usufruitier
            // l'usufruit rejoint la nue-propriété sans taxe
            ()
        }
        
        if invest.ownership.hasABareOwner(named: decedentName) {
            // le capital de l'assurane vie est démembré
            // le défunt est un nue-propriétaire
            // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire (la NP rejoint l'UF)
            fatalError("lifeInsuraceSuccession: cas non traité (capital démembré et le défunt est nue-propriétaire)")
        }
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
    ///   - invest: l'investissemment à analyser
    ///   - year: année du décès - 1
    ///   - massesSuccession: (héritier, base taxable)
    fileprivate func undismemberedLifeInsuranceSuccessionMasses
    (of decedentName  : String,
     spouseName       : String?,
     childrenName     : [String]?,
     for invest       : FinancialEnvelopP,
     massesSuccession : inout NameValueDico) {
        guard var clause = invest.clause else { return }
        
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
        
        // faire la différence après / avant pour connaître les masses héritées
        ownedValuesAfterTranmission.forEach { (newOwnerName, newOwnedvalue) in
            // différence après - avant
            let oldOwnedValue = ownedValuesBeforeTranmission[newOwnerName] ?? 0.0
            let increase = max(0.0, newOwnedvalue - oldOwnedValue)
            
            // s'il y a enrichissement
            if increase > 0.0 {
                if massesSuccession[newOwnerName] != nil {
                    // incrémenter
                    massesSuccession[newOwnerName]! += newOwnedvalue
                } else {
                    massesSuccession[newOwnerName] = newOwnedvalue
                }
            }
        }
    }
    
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
    fileprivate func lifeInsuraceInheritanceValue(in patrimoine   : Patrimoin,
                                                  of decedentName : String,
                                                  atEndOf year    : Int) -> Double {
        var taxable                                             : Double = 0
        patrimoine.forEachOwnable { ownable in
            taxable += ownable.ownedValue(by                : decedentName,
                                          atEndOf           : year,
                                          evaluationContext : .lifeInsuranceSuccession)
        }
        return taxable
    }
}