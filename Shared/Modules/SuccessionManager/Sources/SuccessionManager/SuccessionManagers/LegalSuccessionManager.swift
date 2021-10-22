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
import FiscalModel
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

    /// Calcule la succession légale d'un défunt `decedentName`et retourne
    /// une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - decedentName: nom du défunt
    ///   - year: année du décès
    ///   - fiscalModel: modèle fiscal à utiliser
    /// - Returns: Succession légale du défunt incluant la table des héritages et droits de succession pour chaque héritier
    public func legalSuccession(of decedentName   : String,
                                with patrimoine   : Patrimoin) -> Succession {

        // Calcul de la masse successorale taxable du défunt
        // WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
        let _masseSuccessorale = masseSuccessorale(in : patrimoine,
                                                   of : decedentName)
        //        print("  Masse successorale légale = \(totalTaxableInheritance.rounded())")
        
        // Calculer la part d'héritage du conjoint
        // Rechercher l'option fiscale du conjoint survivant et calculer sa part d'héritage
        if let conjointSurvivant =
            family.members.items.first(where: { member in
                member is Adult && member.isAlive(atEndOf: year) && member.displayName != decedentName
            }) {
            // il y a un conjoint survivant
            let inheritances = spouseInheritance(masseSuccessorale : _masseSuccessorale,
                                                 conjointSurvivant : conjointSurvivant)
            //        print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
            return Succession(kind         : .legal,
                              yearOfDeath  : year,
                              decedentName : decedentName,
                              taxableValue : _masseSuccessorale,
                              inheritances : inheritances)

        } else if family.nbOfChildrenAlive(atEndOf: year) > 0 {
            // pas de conjoint survivant, les enfants survivants se partagent l'héritage
            let inheritanceSharesForChild = InheritanceDonation.childShare(nbChildren: family.nbOfChildrenAlive(atEndOf: year))
            let inheritances = childrenInheritance(inheritanceShareForChild : inheritanceSharesForChild,
                                                   masseSuccessorale        : _masseSuccessorale)
            //        print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
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
    ///   - fiscalModel: model fiscal
    /// - Returns: héritage légal du conjoint
    func spouseInheritance(masseSuccessorale : Double,
                           conjointSurvivant : Person) -> [Inheritance] {
        // % d'héritage résultants de l'option fiscale retenue par le conjoint pour chacun des héritiers
        let inheritanceShares = (conjointSurvivant as! Adult)
            .fiscalOption
            .sharedValues(nbChildren        : family.nbOfChildrenAlive(atEndOf: year),
                          spouseAge         : conjointSurvivant.age(atEndOf: year),
                          demembrementModel : fiscalModel.demembrement)

        // calculer la part d'héritage du conjoint
        let share = inheritanceShares.forSpouse
        let brut  = masseSuccessorale * share

        // calculer les droits de succession du conjoint
        // TODO: le sortir d'une fonction du modèle fiscal
        let tax = 0.0

        //            print("  Part d'héritage de \(conjointSurvivant.displayName) = \(brut.rounded()) (\((share*100.0).rounded())%)")
        //            print("    Taxe = \(tax.rounded())")
        var inheritances = [Inheritance(personName : conjointSurvivant.displayName,
                                        percent    : share,
                                        brut       : brut,
                                        net        : brut - tax,
                                        tax        : tax)]
        // les enfants
        inheritances += childrenInheritance(inheritanceShareForChild : inheritanceShares.forChild,
                                            masseSuccessorale        : masseSuccessorale)

        return inheritances
    }

    /// Calcule de l'héritage légal des enfants
    /// - Parameters:
    ///   - inheritanceShareForChild: part dévolue à chaque enfant
    ///   - masseSuccessorale: masse successorale du défunt
    ///   - fiscalModel: model fiscal
    /// - Returns: héritage légal des enfants
    func childrenInheritance(inheritanceShareForChild : Double,
                             masseSuccessorale        : Double) -> [Inheritance] {
        var inheritances: [Inheritance] = []

        if family.nbOfAdults > 0 {
            // Calcul de la part revenant à chaque enfant compte tenu de l'option fiscale du conjoint
            family.childrenAliveName(atEndOf: year)?.forEach { childName in
                // un enfant
                // calculer la part d'héritage d'un enfant
                let share = inheritanceShareForChild
                let brut  = masseSuccessorale * share

                // caluler les droits de succession du conjoint
                let heritageOfChild = try! fiscalModel.inheritanceDonation.heritageOfChild(partSuccession: brut)

                //                    print("  Part d'héritage de \(child.displayName) = \(brut.rounded()) (\(share.rounded())%)")
                //                    print("    Taxe = \(inheritance.taxe.rounded())")
                inheritances.append(Inheritance(personName : childName,
                                                percent    : share,
                                                brut       : brut,
                                                net        : heritageOfChild.netAmount,
                                                tax        : heritageOfChild.taxe))
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
                                  of decedentName : String) -> Double {
        var taxable: Double = 0
//        print("décédé: \(decedent.displayName)")
        patrimoine.forEachOwnable { ownable in
            taxable += ownable.ownedValue(by                : decedentName,
                                          atEndOf           : year - 1,
                                          evaluationContext : .legalSuccession)
//            print("Actif: \(ownable.name)")
//            print("Valeur légale taxable: \(taxable.k€String)")
        }
        return taxable
    }
}
