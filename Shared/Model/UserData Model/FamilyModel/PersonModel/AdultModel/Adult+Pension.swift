//
//  Adult+Pension.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import FiscalModel
import RetirementModel
import ModelEnvironment

// MARK: - EXTENSION: Retraite Régime Général
extension Adult {
    // MARK: - Computed Properties
    
    var dateOfPensionLiquid              : Date { // computed
        Date.calendar.date(from: dateOfPensionLiquidComp)!
    } // computed
    var dateOfPensionLiquidComp          : DateComponents { // computed
        let liquidDate = Date.calendar.date(byAdding: ageOfPensionLiquidComp, to: birthDate)
        return Date.calendar.dateComponents([.year, .month, .day], from: liquidDate!)
    } // computed
    var displayDateOfPensionLiquid       : String { // computed
        mediumDateFormatter.string(from: dateOfPensionLiquid)
    } // computed
    
    // MARK: - Methods
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime général
    /// - Parameter year: première année incluant des revenus
    func isPensioned(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfPensionLiquid.year <= year)
    }
    func pensionRegimeGeneral(during year: Int, using model: Model)
    -> (brut: Double, net: Double) {
        // pension du régime général
        if let (brut, net) =
            model.retirementModel.regimeGeneral.pension(
                birthDate                : birthDate,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployementAllocation(using: model),
                dateOfPensionLiquid      : dateOfPensionLiquid,
                lastKnownSituation       : lastKnownPensionSituation,
                nbEnfant                 : 3,
                during                   : year) {
            return (brut, net)
        } else {
            return (0, 0)
        }
    }
    func pensionRegimeGeneral(using model: Model) -> (brut: Double, net: Double) {
        // pension du régime général
        if let (brut, net) =
            model.retirementModel.regimeGeneral.pension(
                birthDate                : birthDate,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployementAllocation(using: model),
                dateOfPensionLiquid      : dateOfPensionLiquid,
                lastKnownSituation       : lastKnownPensionSituation,
                nbEnfant                 : 3) {
            return (brut, net)
        } else {
            return (0, 0)
        }
    }

}

// MARK: - EXTENSION: Retraite Régime Complémentaire
extension Adult {
    // MARK: - Computed Properties
    
    var dateOfAgircPensionLiquid              : Date { // computed
        Date.calendar.date(from: dateOfAgircPensionLiquidComp)!
    } // computed
    var dateOfAgircPensionLiquidComp          : DateComponents { // computed
        let liquidDate = Date.calendar.date(byAdding: ageOfAgircPensionLiquidComp, to: birthDate)
        return Date.calendar.dateComponents([.year, .month, .day], from: liquidDate!)
    } // computed
    var displayDateOfAgircPensionLiquid       : String { // computed
        mediumDateFormatter.string(from: dateOfAgircPensionLiquid)
    } // computed

    // MARK: - Methods
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime complémentaire
    /// - Parameter year: première année incluant des revenus
    func isAgircPensioned(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfAgircPensionLiquid.year <= year)
    }
    func pensionRegimeAgirc(during year : Int,
                            using model : Model)
    -> (brut: Double, net: Double) {
        if let pensionAgirc =
            model.retirementModel.regimeAgirc.pension(
                lastAgircKnownSituation  : lastKnownAgircPensionSituation,
                birthDate                : birthDate,
                lastKnownSituation       : lastKnownPensionSituation,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployementAllocation(using: model),
                dateOfPensionLiquid      : dateOfAgircPensionLiquid,
                nbEnfantNe               : nbOfChildren(),
                nbEnfantACharge          : nbOfFiscalChildren(during: year),
                during                   : year) {
            return (pensionAgirc.pensionBrute,
                    pensionAgirc.pensionNette)
        } else {
            return (0, 0)
        }
    }
    func pensionRegimeAgirc(using model: Model) -> (brut: Double, net: Double) {
        if let pensionAgirc =
            model.retirementModel.regimeAgirc.pension(
                lastAgircKnownSituation  : lastKnownAgircPensionSituation,
                birthDate                : birthDate,
                lastKnownSituation       : lastKnownPensionSituation,
                dateOfRetirement         : dateOfRetirement,
                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployementAllocation(using: model),
                dateOfPensionLiquid      : dateOfAgircPensionLiquid,
                nbEnfantNe               : Adult.adultRelativesProvider.nbOfChildren,
                nbEnfantACharge          : Adult.adultRelativesProvider.nbOfFiscalChildren(during: dateOfAgircPensionLiquid.year)) {
            return (pensionAgirc.pensionBrute,
                    pensionAgirc.pensionNette)
        } else {
            return (0, 0)
        }
    } // computed
}

// MARK: - EXTENSION: Retraite Tous Régimes
extension Adult {
    /// Calcul de la pension de retraite
    /// - Parameter year: année
    /// - Returns: pension brute, nette de charges sociales, taxable à l'IRPP
    func pension(during year   : Int,
                 withReversion : Bool = true,
                 using model   : Model) -> BrutNetTaxable {
        guard isAlive(atEndOf: year) else {
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
        var brut = 0.0
        var net  = 0.0
        // pension du régime général
        if isPensioned(during: year) {
            let pension = pensionRegimeGeneral(during: year, using: model)
            let nbWeeks = (dateOfPensionLiquidComp.year == year ? (52 - dateOfPensionLiquid.weekOfYear).double() : 52)
            brut += pension.brut * nbWeeks / 52
            net  += pension.net  * nbWeeks / 52
        }
        // ajouter la pension du régime complémentaire
        if isAgircPensioned(during: year) {
            let pension = pensionRegimeAgirc(during: year, using: model)
            let nbWeeks = (dateOfAgircPensionLiquidComp.year == year ? (52 - dateOfAgircPensionLiquid.weekOfYear).double() : 52)
            brut += pension.brut * nbWeeks / 52
            net  += pension.net  * nbWeeks / 52
        }
        if withReversion {
            // ajouter la pension de réversion s'il y en a une
            if let pensionReversion =
                Adult
                .adultRelativesProvider
                .spouseOf(self)?
                .pensionReversionForSpouse(during: year, using: model) {
                brut += pensionReversion.brut
                net  += pensionReversion.net
            }
        }
        let taxable = try! Fiscal.model.pensionTaxes.taxable(brut: brut, net: net)
        return BrutNetTaxable(brut: brut, net: net, taxable: taxable)
    }
    
    /// Calcul de la pension de réversion laissée au conjoint
    /// - Parameter year: année
    /// - Returns: pension de réversion laissée au conjoint
    /// - Warning: pension laissée au conjoint
    func pensionReversionForSpouse(during year : Int,
                                   using model : Model)
    -> (brut: Double, net: Double)? {
        // la personne est décédée
        guard !isAlive(atEndOf: year) else {
            // la personne est vivante => pas de pension de réversion
            return nil
        }
        // le conjoint existe
        guard let spouse = Adult.adultRelativesProvider.spouseOf(self) else {
            return nil
        }
        // le conjoint est vivant
        guard spouse.isAlive(atEndOf: year) else {
            return nil
        }
        // somme des pensions brutes l'année précédent le décès
        // et de l'année courante pour le conjoint survivant
        let yearBeforeDeath = self.yearOfDeath - 1
        guard isPensioned(during: yearBeforeDeath) else {
            // la personne n'était pas pensionnée avant son décès => pas de pension de réversion
            return nil
        }
        let pensionDuDecede = self.pension(during      : yearBeforeDeath,
                                           withReversion : false,
                                           using         : model)
        let pensionDuConjoint = spouse.pension(during        : year,
                                               withReversion : false,
                                               using         : model)
        let pensionTotaleAvantDeces = (brut: pensionDuDecede.brut + pensionDuConjoint.brut,
                                       net : pensionDuDecede.net  + pensionDuConjoint.net)
        // la pension du conjoint survivant, avec réversion, est limitée à un % de la somme des deux
        let pensionBruteApresDeces =
            model.retirementModel.reversion.pensionReversion(pensionDecedent : pensionDuDecede.brut,
                                                             pensionSpouse   : pensionDuConjoint.brut)
        // le complément de réversion est calculé en conséquence
        let reversionBrut = zeroOrPositive(pensionBruteApresDeces - pensionDuConjoint.brut)
        let reversionNet  = reversionBrut * (pensionTotaleAvantDeces.net / pensionTotaleAvantDeces.brut)
        return (reversionBrut, reversionNet)
    }
}
