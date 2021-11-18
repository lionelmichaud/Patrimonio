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

// Créances de restitution d'un Quasi-Usufruitier envers les Nu-propriétaires
public typealias CreanceDeRestituationDico = [String : NameValueDico]

// Gestionnaire de transmission d'Assurances Vies
struct LifeInsuranceSuccessionManager {
    
    // MARK: - Nested Types

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
    
    struct CapitauxDeces: Equatable {
        var fiscal   : (brut: Double, net: Double) = (0, 0)
        var received : (brut: Double, net: Double) = (0, 0)
        var creance  : Double = 0
        
        static func == (lhs: LifeInsuranceSuccessionManager.CapitauxDeces,
                        rhs: LifeInsuranceSuccessionManager.CapitauxDeces) -> Bool {
            lhs.creance == rhs.creance &&
                lhs.fiscal == rhs.fiscal &&
                lhs.received == rhs.received
        }
    }
    
    typealias NameCapitauxDecesDico = [String : CapitauxDeces]
    
    // MARK: - Properties
    
    var fiscalModel   : Fiscal.Model
    var family        : FamilyProviderP
    var year          : Int
    // capitaux décès reçu par chaque héritier
    var capitauxDeces             = NameCapitauxDecesDico()
    // créances de restitution de quasi-usufruits d'un héritier (UF) envers les autres (NP)
    var creanceDeRestituationDico = CreanceDeRestituationDico()

    // MARK: - Initializers

    init(using fiscalModel : Fiscal.Model,
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
    mutating func succession(of decedentName : String,
                             with patrimoine : Patrimoin,
                             spouseName      : String?,
                             childrenName    : [String]?,
                             verbose         : Bool = false) -> Succession {
        
        capitauxDeces             = NameCapitauxDecesDico()
        creanceDeRestituationDico = CreanceDeRestituationDico()
        var inheritances: [Inheritance] = []

        let financialEnvelops: [FinancialEnvelopP] =
            patrimoine.assets.freeInvests.items + patrimoine.assets.periodicInvests.items
        
        // calculer le montant de l'abattement de chaque héritier
        let abattementsDico = abattementsParPersonne(for          : financialEnvelops,
                                                     spouseName   : spouseName,
                                                     childrenName : childrenName,
                                                     verbose      : verbose)
        
        // calculer les capitaux décès taxables reçus par chaque héritier
        let capitaux = capitauxDecesTaxableRecusParPersonne(of      : decedentName,
                                                            with    : financialEnvelops,
                                                            verbose : verbose)
        capitaux.taxable.forEach { heritier, value in
            if capitauxDeces[heritier] == nil {
                capitauxDeces[heritier] = CapitauxDeces(fiscal: (brut: value, net: 0))
            } else {
                capitauxDeces[heritier]!.fiscal.brut += value
            }
        }
        capitaux.received.forEach { heritier, value in
            if capitauxDeces[heritier] == nil {
                capitauxDeces[heritier] = CapitauxDeces(received: (brut: value, net: 0))
            } else {
                capitauxDeces[heritier]!.received.brut += value
            }
        }
        creanceDeRestituationDico = capitaux.creances
        creanceDeRestituationDico.forEach { _, creances in
            creances.forEach { creancier, value in
                if capitauxDeces[creancier] == nil {
                    capitauxDeces[creancier] = CapitauxDeces(creance: value)
                } else {
                    capitauxDeces[creancier]!.creance += value
                }
            }
        }

        // calcul de la masse totale taxable et reçue réellement
        let totalTaxableValue  = capitaux.taxable.values.sum()
        let totalReceivedValue = capitaux.received.values.sum()
        if verbose {
            print("Total des capitaux décès taxables assurance vie = \(totalTaxableValue.rounded())")
            print("Total des capitaux décès reçus d'assurance vie  = \(totalReceivedValue.rounded())")
        }

        // calculer l'héritage de chaque membre de la famille autre que le défunt
        // à partir des capitaux décès taxables et des abattements
        for member in family.members.items where member.isAlive(atEndOf: year) && member.displayName != decedentName {
            let name = member.displayName
            if let capitauxTaxables = capitaux.taxable[name] {
                // calculer les taxes de transmission
                var heritageNetTax = (netAmount: 0.0, taxe: 0.0)
                if member is Adult {
                    // le conjoint
                    heritageNetTax =
                        fiscalModel.lifeInsuranceInheritance
                        .heritageNetTaxToConjoint(partSuccession: capitauxTaxables)
                } else {
                    // les enfants
                    heritageNetTax =
                        try! fiscalModel.lifeInsuranceInheritance
                        .heritageNetTaxToChild(partSuccession: capitauxTaxables,
                                               fracAbattement: abattementsDico[name])
                }
                capitauxDeces[name]!.fiscal.net   = heritageNetTax.netAmount
                let receivedNet = capitauxDeces[name]!.received.brut == 0.0 ? 0.0 : capitauxDeces[name]!.received.brut - heritageNetTax.taxe
                capitauxDeces[name]!.received.net = receivedNet
                
                if verbose {
                    print(
                        """
                        Part d'héritage de \(member.displayName) = \(capitauxTaxables.rounded()) (\((capitauxTaxables/totalTaxableValue*100.0).rounded()) %
                           Brut     = \(capitauxTaxables.rounded())
                           Taxe     = \(heritageNetTax.taxe.rounded())
                           Net      = \(heritageNetTax.netAmount.rounded())
                           Reçu     = \(capitauxDeces[name]!.received.brut.rounded())
                           Reçu net = \(capitauxDeces[name]!.received.net.rounded())
                           Créance  = \(capitauxDeces[name]?.creance.rounded() ?? 0)

                        """)
                }
                
                inheritances.append(Inheritance(personName    : name,
                                                percentFiscal : capitauxTaxables / totalTaxableValue,
                                                brutFiscal    : capitauxTaxables,
                                                abatFrac      : abattementsDico[name]!,
                                                netFiscal     : heritageNetTax.netAmount,
                                                tax           : heritageNetTax.taxe,
                                                received      : capitauxDeces[name]!.received.brut,
                                                receivedNet   : capitauxDeces[name]!.received.net,
                                                creanceRestit : capitauxDeces[name]?.creance ?? 0))
            }
        }
        
        if verbose {
            print(
                """
                TOTAL
                   Part      = \(inheritances.sum(for: \.percentFiscal).percentString(digit: 1))
                   Brut      = \(inheritances.sum(for: \.brutFiscal).rounded()))
                   Taxe      = \(inheritances.sum(for: \.tax).rounded()))
                   Net       = \(inheritances.sum(for: \.netFiscal).rounded()))
                   Reçu      = \(inheritances.sum(for: \.received).rounded()))
                   Reçu net  = \(inheritances.sum(for: \.receivedNet).rounded())
                   Créance   = \(inheritances.sum(for: \.creanceRestit).rounded())
                """)
        }
        return Succession(kind         : .lifeInsurance,
                          yearOfDeath  : year,
                          decedentName : decedentName,
                          taxableValue : totalTaxableValue,
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
    fileprivate func lifeInsuranceInheritanceValue(in patrimoine   : Patrimoin,
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
