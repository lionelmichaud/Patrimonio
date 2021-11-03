//
//  LifeInsuranceSuccessionManager.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import NamedValue
import Ownership
import AssetsModel
import Succession
import FiscalModel
import PersonModel
import PatrimoineModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine",
                               category: "Model.LifeInsuranceSuccessionManager")

struct LifeInsuranceSuccessionManager {
    
    // MARK: - Types

    typealias AbattementPersonel = NamedValue

    struct CoupleUFNP: Hashable, Equatable, CustomStringConvertible {
        var UF: AbattementPersonel
        var NP: AbattementPersonel
        var description: String {
            """

            Couple :
                UF : \(String(describing: UF))
                NP : \(String(describing: NP))
            """
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(UF.name)
            hasher.combine(UF.value)
            hasher.combine(NP.name)
            hasher.combine(NP.value)
        }
        static func == (lhs: CoupleUFNP,
                        rhs: CoupleUFNP) -> Bool {
            lhs.NP == rhs.NP && lhs.UF == rhs.UF
        }
    }
    
    typealias SetAbatCoupleUFNP = Set<CoupleUFNP>
    
    // MARK: - Properties
    
    var fiscalModel : Fiscal.Model
    var family      : FamilyProviderP
    var year        : Int

    // MARK: - Initializers

    public init(using fiscalModel : Fiscal.Model,
                familyProvider    : FamilyProviderP,
                atEndOf year      : Int) {
        self.family      = familyProvider
        self.fiscalModel = fiscalModel
        self.year        = year
    }

    // MARK: - Methods

    /// Calcule la transmission d'assurance vie d'un `patrimoine` au décès de `decedentName` et retourne
    /// une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - patrimoine: patrimoine
    ///   - spouseName: nom du conjoint du défunt
    ///   - childrenName: nom des enfants du défunt
    /// - Returns: Succession du défunt incluant la table des héritages et droits de succession pour chaque héritier
    func lifeInsuranceSuccession(of decedentName : String,
                                 with patrimoine : Patrimoin,
                                 spouseName      : String?,
                                 childrenName    : [String]?,
                                 verbose         : Bool = false) -> Succession {
        var inheritances  : [Inheritance] = []
        
        let financialEnvelops: [FinancialEnvelopP] =
            patrimoine.assets.freeInvests.items + patrimoine.assets.periodicInvests.items
        
        // calculer le montant de l'abattement de chaque héritier
        let abattementsDico = abattementsParPersonne(of           : decedentName,
                                                     with         : financialEnvelops,
                                                     spouseName   : spouseName,
                                                     childrenName : childrenName,
                                                     verbose      : verbose)
        
        // calculer les capitaux décès taxables reçus par chaque héritier
        let capitauxDeces = capitauxDecesTaxablesParPersonne(of           : decedentName,
                                                             with         : financialEnvelops,
                                                             spouseName   : spouseName,
                                                             childrenName : childrenName,
                                                             verbose      : verbose)

        // calcul de la masse totale taxable
        let totalTaxableInheritanceValue = capitauxDeces.values.sum()
        if verbose {
            print("Total des capitaux décès taxables assurance vie = \(totalTaxableInheritanceValue.rounded())")
        }

        // calculer l'héritage de chaque membre de la famille autre que le défunt
        // à partir des capitaux décès reçus et des abattements
        for member in family.members.items where member.displayName != decedentName {
            if let capitaux = capitauxDeces[member.displayName] {
                var heritageNetTax = (netAmount: 0.0, taxe: 0.0)
                if member is Adult {
                    // le conjoint
                    heritageNetTax =
                        fiscalModel.lifeInsuranceInheritance
                        .heritageNetTaxToConjoint(partSuccession: capitaux)
                } else {
                    // les enfants
                    heritageNetTax =
                        try! fiscalModel.lifeInsuranceInheritance
                        .heritageNetTaxToChild(partSuccession: capitaux,
                                               fracAbattement: abattementsDico[member.displayName])
                }
                if verbose {
                    print("  Part d'héritage de \(member.displayName) = \(capitaux.rounded()) (\((capitaux/totalTaxableInheritanceValue*100.0).rounded()) %)")
                    print("    Taxe = \(heritageNetTax.taxe.rounded())")
                }
                inheritances.append(Inheritance(personName : member.displayName,
                                                percent    : capitaux / totalTaxableInheritanceValue,
                                                brut       : capitaux,
                                                abatFrac   : abattementsDico[member.displayName]!,
                                                net        : heritageNetTax.netAmount,
                                                tax        : heritageNetTax.taxe))
            }
        }
        
        if verbose {
            print("  Part total = ", inheritances.sum(for: \.percent))
            print("  Brut total = ", inheritances.sum(for: \.brut).rounded())
            print("  Taxe total = ", inheritances.sum(for: \.tax).rounded())
            print("  Net total  = ", inheritances.sum(for: \.net).rounded())
        }
        return Succession(kind         : .lifeInsurance,
                          yearOfDeath  : year,
                          decedentName : decedentName,
                          taxableValue : totalTaxableInheritanceValue,
                          inheritances : inheritances)
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
                                                  of decedentName : String) -> Double {
        var taxable                                             : Double = 0
        patrimoine.forEachOwnable { ownable in
            taxable += ownable.ownedValue(by                : decedentName,
                                          atEndOf           : year,
                                          evaluationContext : .lifeInsuranceSuccession)
        }
        return taxable
    }
}
