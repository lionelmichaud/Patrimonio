//
//  LegalSuccessionManager.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import FiscalModel
import Ownership
import Succession
import PersonModel
import PatrimoineModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.LegalSuccessionManager")

public struct LegalSuccessionManager {
    
    // MARK: - Properties

    private var fiscalModel : Fiscal.Model
    private var family      : FamilyProviderP
    private var year        : Int

    // MARK: - Initializers

    public init(using fiscalModel : Fiscal.Model,
                familyProvider    : FamilyProviderP,
                atEndOf year      : Int) {
        self.fiscalModel = fiscalModel
        self.family      = familyProvider
        self.year        = year
    }

    // MARK: - Methods

    /// Calcule la succession légale d'un défunt `decedentName`et retourne
    /// une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - decedentName: nom du défunt
    ///   - isFirstDecedent: true si le `decedentName` est le premier des défunts de l'année en cours
    ///   - patrimoine: patrimoine
    ///   - previousSuccession: succession précédente pour les assuarnces vies
    /// - Returns: Succession légale du défunt incluant la table des héritages et droits de succession pour chaque héritier
    public func succession(of decedentName    : String,
                           isFirstDecedent    : Bool = true,
                           with patrimoine    : Patrimoin,
                           previousSuccession : Succession?,
                           verbose            : Bool = false) -> Succession {

        // Calcul de la masse successorale taxable du défunt
        // WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
        let _masseSuccessorale = masseSuccessorale(in      : patrimoine,
                                                   of      : decedentName,
                                                   verbose : verbose)
        if verbose {
            print("Masse successorale légale = \(_masseSuccessorale.rounded())")
        }

        // Calculer la part d'héritage du conjoint (s'il est vivant à la fin de l'année précédente,
        // et s'il n'est pas pré-décédé)
        // Rechercher l'option fiscale du conjoint survivant et calculer sa part d'héritage
        if let conjointSurvivant = family.spouseOf(family.member(withName: decedentName)! as! Adult),
           conjointSurvivant.isAlive(atEndOf: year - 1),
           isFirstDecedent {
            // il y a un conjoint survivant
            let inheritances = spouseAndChildrenInheritance(masseSuccessorale : _masseSuccessorale,
                                                            conjointSurvivant : conjointSurvivant,
                                                            previousSuccession: previousSuccession,
                                                            verbose           : verbose)
            if verbose {
                print("  Part totale = ", inheritances.sum(for: \.percentFiscal))
                print("  Brut total  = ", inheritances.sum(for: \.brutFiscal).rounded())
                print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
                print("  Net total   = ", inheritances.sum(for: \.netFiscal).rounded())
            }
            return Succession(kind         : .legal,
                              yearOfDeath  : year,
                              decedentName : decedentName,
                              taxableValue : _masseSuccessorale,
                              inheritances : inheritances)

        } else if family.nbOfChildrenAlive(atEndOf: year) > 0 {
            // pas de conjoint survivant, les enfants survivants se partagent l'héritage
            let inheritanceSharesForChild = InheritanceDonation.childShare(nbChildren: family.nbOfChildrenAlive(atEndOf: year))
            let inheritances = childrenInheritance(inheritanceShareForChild : inheritanceSharesForChild,
                                                   masseSuccessorale        : _masseSuccessorale,
                                                   previousSuccession       : previousSuccession,
                                                   verbose                  : verbose)
            if verbose {
                print("  Part totale = ", inheritances.sum(for: \.percentFiscal))
                print("  Brut total  = ", inheritances.sum(for: \.brutFiscal).rounded())
                print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
                print("  Net total   = ", inheritances.sum(for: \.netFiscal).rounded())
            }
            return Succession(kind         : .legal,
                              yearOfDeath  : year,
                              decedentName : decedentName,
                              taxableValue : _masseSuccessorale,
                              inheritances : inheritances)

        } else {
            // pas de conjoint survivant, pas d'enfant survivant
            return Succession(kind         : .legal,
                              yearOfDeath  : year,
                              decedentName : decedentName,
                              taxableValue : _masseSuccessorale,
                              inheritances : [])
        }
    }

    /// Calcule de l'héritage légal du conjoint
    /// - Parameters:
    ///   - masseSuccessorale: masse successorale du défunt
    ///   - conjointSurvivant: nom du conjoint survivant
    ///   - previousSuccession: succession précédente pour les assuarnces vies
    /// - Returns: héritage légal du conjoint
    func spouseAndChildrenInheritance(masseSuccessorale  : Double,
                                      conjointSurvivant  : Adult,
                                      previousSuccession : Succession?,
                                      verbose            : Bool = false) -> [Inheritance] {
        // % d'héritage résultants de l'option fiscale retenue par le conjoint pour chacun des héritiers
        let inheritanceShares = conjointSurvivant
            .fiscalOption
            .sharedValues(nbChildren        : family.nbOfChildrenAlive(atEndOf: year),
                          spouseAge         : conjointSurvivant.age(atEndOf: year),
                          demembrementModel : fiscalModel.demembrement)

        // calculer la part d'héritage du conjoint
        let share = inheritanceShares.forSpouse
        let brutBeforeCreanceRestit = masseSuccessorale * share
        let creanceRestit           = min(previousSuccession?.creanceRestit(of : conjointSurvivant.displayName) ?? 0.0,
                                          brutBeforeCreanceRestit)
        let brutAfterCreanceRestit  = brutBeforeCreanceRestit - creanceRestit

        // calculer les droits de succession du conjoint
        // TODO: le sortir d'une fonction du modèle fiscal
        let tax = 0.0
        let net = brutAfterCreanceRestit - tax

        var inheritances = [Inheritance(personName    : conjointSurvivant.displayName,
                                        percentFiscal : share,
                                        brutFiscal    : brutAfterCreanceRestit,
                                        abatFrac      : 1.0,
                                        netFiscal     : net,
                                        tax           : tax,
                                        received      : 0.0,
                                        receivedNet   : 0.0 - tax,
                                        creanceRestit : -creanceRestit)]
        if verbose { print(String(describing: inheritances.last)) }

        // les enfants
        inheritances += childrenInheritance(inheritanceShareForChild : inheritanceShares.forChild,
                                            masseSuccessorale        : masseSuccessorale,
                                            previousSuccession       : previousSuccession,
                                            verbose                  : verbose)

        return inheritances
    }

    /// Calcule de l'héritage légal des enfants
    /// - Parameters:
    ///   - inheritanceShareForChild: part dévolue à chaque enfant
    ///   - masseSuccessorale: masse successorale du défunt
    ///   - previousSuccession: succession précédente pour les assuarnces vies
    /// - Returns: héritage légal des enfants
    func childrenInheritance(inheritanceShareForChild : Double,
                             masseSuccessorale        : Double,
                             previousSuccession       : Succession?,
                             verbose                  : Bool = false) -> [Inheritance] {
        var inheritances: [Inheritance] = []

        if family.nbOfAdults > 0 {
            // Calcul de la part revenant à chaque enfant compte tenu de l'option fiscale du conjoint
            family.childrenAliveName(atEndOf: year)?.forEach { childName in
                // un enfant
                // calculer la part d'héritage d'un enfant
                let share                   = inheritanceShareForChild
                let brutBeforeCreanceRestit = masseSuccessorale * share
                let creanceRestit           = min(previousSuccession?.creanceRestit(of : childName) ?? 0.0,
                                                  brutBeforeCreanceRestit)
                let brutAfterCreanceRestit  = brutBeforeCreanceRestit - creanceRestit
                
                // caluler les droits de succession du conjoint
                let heritageOfChild =
                    try! fiscalModel.inheritanceDonation.heritageOfChild(partSuccession: brutAfterCreanceRestit)
                
                inheritances.append(Inheritance(personName    : childName,
                                                percentFiscal : share,
                                                brutFiscal    : brutAfterCreanceRestit,
                                                abatFrac      : 1.0,
                                                netFiscal     : heritageOfChild.netAmount,
                                                tax           : heritageOfChild.taxe,
                                                received      : 0.0,
                                                receivedNet   : 0.0 - heritageOfChild.taxe,
                                                creanceRestit : -creanceRestit))
                if verbose { print(String(describing: inheritances.last)) }
            }
        }

        return inheritances
    }

    /// Calcule l'a masse successorale d'un `patrimoine` à la succession d'un défunt  nommé`decedentName`
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - decedentName: nom du défunt
    ///   - year: année du décès - 1
    /// - Returns: Masse successorale nette taxable du défunt
    /// - WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
    public func masseSuccessorale(in patrimoine   : Patrimoin,
                                  of decedentName : String,
                                  verbose         : Bool = false) -> Double {
        var taxable: Double = 0
        if verbose { print("décédé: \(decedentName)") }
        patrimoine.forEachOwnable { ownable in
            guard ownable.isOwnedBySomebody else { return }
            let _taxable = ownable.ownedValue(by                : decedentName,
                                              atEndOf           : year - 1,
                                              evaluationContext : .legalSuccession)
            if verbose {
                print("Actif: \(ownable.name)")
                print(" => Valeur légale taxable: \(_taxable.rounded())")
            }
            taxable += _taxable
        }
        return taxable
    }
}
