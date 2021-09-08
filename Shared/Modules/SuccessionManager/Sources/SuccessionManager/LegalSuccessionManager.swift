//
//  LegalSuccessionManager.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import FiscalModel
import Ownership
import Succession
import ModelEnvironment
import PersonModel
import PatrimoineModel

public struct LegalSuccessionManager {
    
    // MARK: - Initializers

    public init() {    }

    // MARK: - Methods

    /// Calcule la succession légale d'un défunt `decedent`et retourne
    /// une table des héritages et droits de succession pour chaque héritier
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - decedent: défunt
    ///   - year: année du décès
    ///   - model: modèle d'envrionment à utiliser
    /// - Returns: Succession légale du défunt incluant la table des héritages et droits de succession pour chaque héritier
    public func legalSuccession(in patrimoine : Patrimoin,
                                of decedent   : Person,
                                atEndOf year  : Int,
                                using model   : Model) -> Succession {

        var inheritances      : [Inheritance] = []
        var inheritanceShares : (forChild: Double, forSpouse: Double) = (0, 0)
        
        guard let family = Patrimoin.familyProvider else {
            return Succession(kind         : .legal,
                              yearOfDeath  : year,
                              decedentName : decedent.displayName,
                              taxableValue : 0,
                              inheritances : [])
        }
        
        // Calcul de la masse successorale taxable du défunt
        // WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
        let totalTaxableInheritance = taxableInheritanceValue(in      : patrimoine,
                                                              of      : decedent,
                                                              atEndOf : year - 1)
        //        print("  Masse successorale légale = \(totalTaxableInheritance.rounded())")
        
        // Calculer la part d'héritage du conjoint
        // Rechercher l'option fiscale du conjoint survivant et calculer sa part d'héritage
        if let conjointSurvivant = family.members.items.first(where: { member in
            member is Adult && member.isAlive(atEndOf: year) && member != decedent
        }) {
            // il y a un conjoint survivant
            // % d'héritage résultants de l'option fiscale retenue par le conjoint pour chacun des héritiers
            inheritanceShares =
                (conjointSurvivant as! Adult)
                .fiscalOption
                .sharedValues(nbChildren        : family.nbOfChildrenAlive(atEndOf: year),
                              spouseAge         : conjointSurvivant.age(atEndOf: year),
                              demembrementModel : model.fiscalModel.demembrement)
            
            // calculer la part d'héritage du conjoint
            let share = inheritanceShares.forSpouse
            let brut  = totalTaxableInheritance * share
            
            // calculer les droits de succession du conjoint
            // TODO: le sortir d'une fonction du modèle fiscal
            let tax = 0.0
            
            //            print("  Part d'héritage de \(conjointSurvivant.displayName) = \(brut.rounded()) (\((share*100.0).rounded())%)")
            //            print("    Taxe = \(tax.rounded())")
            inheritances.append(Inheritance(personName : conjointSurvivant.displayName,
                                            percent    : share,
                                            brut       : brut,
                                            net        : brut - tax,
                                            tax        : tax))
        } else if family.nbOfChildrenAlive(atEndOf: year) > 0 {
            // pas de conjoint survivant, les enfants survivants se partagent l'héritage
            inheritanceShares.forSpouse = 0
            inheritanceShares.forChild  = InheritanceDonation.childShare(nbChildren: family.nbOfChildrenAlive(atEndOf: year))
            
        } else {
            // pas de conjoint survivant, pas d'enfant survivant
            return Succession(kind         : .legal,
                              yearOfDeath  : year,
                              decedentName : decedent.displayName,
                              taxableValue : totalTaxableInheritance,
                              inheritances : [])
        }
        
        if family.nbOfAdults > 0 {
            // Calcul de la part revenant à chaque enfant compte tenu de l'option fiscale du conjoint
            for member in family.members.items {
                if let child = member as? Child {
                    // un enfant
                    // calculer la part d'héritage d'un enfant
                    let share = inheritanceShares.forChild
                    let brut  = totalTaxableInheritance * share
                    
                    // caluler les droits de succession du conjoint
                    let inheritance = try! model.fiscalModel.inheritanceDonation.heritageOfChild(partSuccession: brut)
                    
                    //                    print("  Part d'héritage de \(child.displayName) = \(brut.rounded()) (\(share.rounded())%)")
                    //                    print("    Taxe = \(inheritance.taxe.rounded())")
                    inheritances.append(Inheritance(personName : child.displayName,
                                                    percent    : share,
                                                    brut       : brut,
                                                    net        : inheritance.netAmount,
                                                    tax        : inheritance.taxe))
                }
            }
        }
        //        print("  Taxe totale = ", inheritances.sum(for: \.tax).rounded())
        return Succession(kind         : .legal,
                          yearOfDeath  : year,
                          decedentName : decedent.displayName,
                          taxableValue : totalTaxableInheritance,
                          inheritances : inheritances)
    }
    
    /// Calcule l'actif net taxable d'un `patrimoine` à la succession d'un défunt `decedent`
    /// - Note: [Reference](https://www.service-public.fr/particuliers/vosdroits/F14198)
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - decedent: défunt
    ///   - year: année du décès - 1
    /// - Returns: Masse successorale nette taxable du défunt
    /// - WARNING: prendre en compte la capital à la fin de l'année précédent le décès. Important pour FreeInvestement.
    public func taxableInheritanceValue(in patrimoine : Patrimoin,
                                        of decedent   : Person,
                                        atEndOf year  : Int) -> Double {
        var taxable: Double = 0
        patrimoine.forEachOwnable { ownable in
            taxable += ownable.ownedValue(by               : decedent.displayName,
                                          atEndOf          : year,
                                          evaluationMethod : .legalSuccession)
        }
        return taxable
    }
}
