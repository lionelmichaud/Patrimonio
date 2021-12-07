//
//  RegimeAgirc.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 16/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import RetirementModel
import AppFoundation
import FiscalModel
import SocioEconomyModel

class RegimeAgircTest: XCTestCase { // swiftlint:disable:this type_body_length
    
    static var regimeAgirc: RegimeAgirc!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = RegimeAgirc.Model(fromFile   : "RegimeAgircModel.json",
                                      fromBundle : Bundle.module)
        RegimeAgircTest.regimeAgirc = RegimeAgirc(model: model)
        
        // inject dependency for tests
        RegimeAgircTest.regimeAgirc.setPensionDevaluationRateProvider(
            SocioEconomy.Model(fromFile   : "SocioEconomyModelConfig.json",
                               fromBundle : Bundle.module)
                .initialized())
        RegimeAgircTest.regimeAgirc.setNetRegimeAgircProviderP(
            Fiscal
                .Model(fromFile   : "FiscalModelConfig.json",
                       fromBundle : Bundle.module)
                .initialized()
                .pensionTaxes)
        RegimeAgircTest.regimeAgirc.setRegimeGeneral(
            RegimeGeneral(model: RegimeGeneral.Model(fromFile: "RegimeGeneralModel.json",
                                                     fromBundle: Bundle.module)))
    }
    
    func date(year: Int, month: Int, day: Int) -> Date {
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : year,
                                         month    : month,
                                         day      : day)
        return Date.calendar.date(from: dateRefComp)!
    }
    
    // MARK: Tests
    
    func test_loading_from_module_bundle() {
        XCTAssertNoThrow(RegimeAgirc.Model(fromFile   : "RegimeAgircModel.json",
                                           fromBundle : Bundle.module),
                         "Failed to read RegimeAgirc.Model from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }

    func test_saving_model_to_test_bundle() throws {
        RegimeAgircTest.regimeAgirc.saveAsJSON(toFile               : "RegimeAgircModel.json",
                                               toBundle             : Bundle.module,
                                               dateEncodingStrategy : .iso8601,
                                               keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func test_valeur_du_point() {
        XCTAssertEqual(1.2714, RegimeAgircTest.regimeAgirc.valeurDuPoint)
        RegimeAgircTest.regimeAgirc.valeurDuPoint = 2.0
        XCTAssertEqual(2.0, RegimeAgircTest.regimeAgirc.valeurDuPoint)
        RegimeAgircTest.regimeAgirc.valeurDuPoint = 1.2714
        XCTAssertEqual(1.2714, RegimeAgircTest.regimeAgirc.valeurDuPoint)
    }
    
    func test_age_minimum() {
        XCTAssertEqual(57, RegimeAgircTest.regimeAgirc.ageMinimum)
        RegimeAgircTest.regimeAgirc.ageMinimum = 60
        XCTAssertEqual(60, RegimeAgircTest.regimeAgirc.ageMinimum)
        RegimeAgircTest.regimeAgirc.ageMinimum = 57
        XCTAssertEqual(57, RegimeAgircTest.regimeAgirc.ageMinimum)
    }
    
   func test_pension_devaluation_rate() {
        XCTAssertEqual(1.0, RegimeAgircTest.regimeAgirc.devaluationRate)
    }
    
    func test_calcul_revaluation_Coef() {
        let dateOfPensionLiquid : Date! = 10.years.ago
        let thisYear = Date.now.year
        
        let devaluationRate = RegimeAgircTest.regimeAgirc.devaluationRate
        XCTAssertEqual(1.0, devaluationRate)

        let revaluationCoef = RegimeAgircTest.regimeAgirc.yearlyRevaluationRate
        XCTAssertEqual(-1.0, revaluationCoef)
        
        let coef = RegimeAgircTest.regimeAgirc.revaluationCoef(during              : thisYear,
                                                               dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertEqual(pow((1.0 + revaluationCoef/100.0), 10.0), coef)
        
//        XCTAssertThrowsError(RegimeAgircTest.regimeAgirc.revaluationCoef(during              : thisYear - 1,
//                                                                         dateOfPensionLiquid : dateOfPensionLiquid))
    }
    
    // MARK: - CAS REELS A VERIFIER AVEC MAREL
 
    func test_cas_lionel_sans_chomage_62_ans() throws {
        let birthDate = self.date(year: 1964, month: 9, day: 22)
        let nbTrimestreAcquis = 139
        let sam               = 37054.0
        let atEndOf     = 2020
        let nbPoints    = 19484
        let pointsParAn = 789

        // dernier relevé connu des caisses de retraite
        let lastKnownSituation = RegimeGeneralSituation(atEndOf           : atEndOf,
                                                        nbTrimestreAcquis : nbTrimestreAcquis,
                                                        sam               : sam)
        let lastAgircKnownSituation = RegimeAgircSituation(atEndOf : atEndOf,
                                                           nbPoints    : nbPoints,
                                                           pointsParAn : pointsParAn)
        
        // Cessation d'activité à 62 ans + ce qu'il faut pour acquérir le dernier trimestre plein
        let dateOfPensionLiquid = (62.years + 10.days).from(birthDate)!
        let dateOfRetirement    = dateOfPensionLiquid
        
        // valeur du point
        let valeurDuPoint = RegimeAgircTest.regimeAgirc.valeurDuPoint
        XCTAssertEqual(1.2714, valeurDuPoint)
        
        /// Projection du nombre de points Agirc sur la base du dernier relevé de points et de la prévision de carrière future
        let projectedNumberOfPoints = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                                        .projectedNumberOfPoints(
                                                            lastAgircKnownSituation  : lastAgircKnownSituation,
                                                            dateOfRetirement         : dateOfPensionLiquid,
                                                            dateOfEndOfUnemployAlloc : nil),
                                                    "Failed projectedNumberOfPoints")
        let dateReleve = lastDayOf(year: atEndOf)
        let delta = Date.calendar.dateComponents([.year, .month, .day],
                                                 from: dateReleve,
                                                 to  : dateOfPensionLiquid)
        let nbPointsAdded =
            delta.year! * pointsParAn +
            Int((delta.month!.double() / 12.0) * pointsParAn.double()) // mois pleins
        let nbPointTheory = lastAgircKnownSituation.nbPoints + nbPointsAdded
        XCTAssertEqual(nbPointTheory, projectedNumberOfPoints)
        
        /// Calcul le coefficient de minoration ou de majoration de la pension complémentaire selon
        let coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                            .coefMinorationMajoration(
                                                birthDate                : birthDate,
                                                lastKnownSituation       : lastKnownSituation,
                                                dateOfRetirement         : dateOfRetirement,
                                                dateOfEndOfUnemployAlloc : nil,
                                                dateOfPensionLiquid      : dateOfPensionLiquid,
                                                during                   : dateOfPensionLiquid.year))
        // 0.78: 20 trim manquant pour atteindre 67 ans
        // 0.93:  7 trim manquant pour le taux plein à 63 ans et 9 mois
        let coefTheory = max(0.93, 0.78)
        XCTAssertEqual(coefTheory, coefMinoration)
        
        // calcul pension avant majoration
        let pensionAvantMajorationPourEnfant = projectedNumberOfPoints.double() * valeurDuPoint * coefMinoration
        print(pensionAvantMajorationPourEnfant)
        
        // Calcul de la majoration pour enfant nés
        let nbEnfantNe = 3
        let coefEnfantNe = RegimeAgircTest.regimeAgirc
            .coefMajorationPourEnfantNe(nbEnfantNe: nbEnfantNe)
        XCTAssertEqual(1.1, coefEnfantNe)
        // plafonnement
        let majorationPourEnfantNe = min(pensionAvantMajorationPourEnfant * (coefEnfantNe - 1.0),
                                         RegimeAgircTest.regimeAgirc.model.majorationPourEnfant.plafondMajoEnfantNe)
        XCTAssertEqual(majorationPourEnfantNe, RegimeAgircTest.regimeAgirc.model.majorationPourEnfant.plafondMajoEnfantNe)

        // Calcul de la majoration pour enfant à charge (non plafonnée)
        var nbEnfantACharge = 2 // 2 jusqu'en 2029, 1 en 2030, 0 ensuite
        let coefEnfantACharge = RegimeAgircTest.regimeAgirc
            .coefMajorationPourEnfantACharge(nbEnfantACharge: nbEnfantACharge)
        let majorationPourEnfantACharge = pensionAvantMajorationPourEnfant * (coefEnfantACharge - 1.0)
        XCTAssertEqual(1.1, coefEnfantACharge)

        // on retient la plus favorable des deux majorations
        let majorationPourEnfant = max(majorationPourEnfantNe, majorationPourEnfantACharge)

        // Pension = Nombre de points X Valeurs du point X Coefficient de minoration X Coefficient de majoration enfants
        let pensionBrute = pensionAvantMajorationPourEnfant + majorationPourEnfant
        var during = dateOfPensionLiquid.year // 2026
        let pension = try XCTUnwrap(RegimeAgircTest.regimeAgirc.pension(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        nbEnfantNe               : nbEnfantNe,
                                        nbEnfantACharge          : nbEnfantACharge,
                                        during                   : during))
        XCTAssertEqual(pension.projectedNbOfPoints, projectedNumberOfPoints)
        XCTAssertEqual(pension.coefMinoration, coefMinoration)
        XCTAssertEqual(pension.majorationPourEnfant, majorationPourEnfant)
        XCTAssertEqual(pension.pensionBrute, pensionBrute)

        nbEnfantACharge = 0 // 2 jusqu'en 2029, 1 en 2030, 0 ensuite
        during = 2030
        let coefReavluation = RegimeAgircTest.regimeAgirc.revaluationCoef(
            during              : during,
            dateOfPensionLiquid : dateOfPensionLiquid)
        let pensionBrute2030plus = (pensionAvantMajorationPourEnfant + majorationPourEnfantNe) * coefReavluation
        let pension2030plus = try XCTUnwrap(RegimeAgircTest.regimeAgirc.pension(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        nbEnfantNe               : nbEnfantNe,
                                        nbEnfantACharge          : nbEnfantACharge,
                                        during                   : during))
        XCTAssertEqual(pension2030plus.projectedNbOfPoints, projectedNumberOfPoints)
        XCTAssertEqual(pension2030plus.coefMinoration, coefMinoration)
        XCTAssertEqual(pension2030plus.majorationPourEnfant, majorationPourEnfantNe)
        XCTAssertEqual(pension2030plus.pensionBrute, pensionBrute2030plus)
        
        print("CAS LIONEL SANS CHOMAGE JUSQU'A 62 ANS:")
        print("  Situation de référence (général):")
        print("  - Date = \(dateReleve.stringLongDate) ")
        print("  - SAM  = \(lastKnownSituation.sam.€String)")
        print("  - Nombre de trimestre acquis = \(nbTrimestreAcquis)")
        print("  Situation de référence (AGIRC-ARCCO:")
        print("  - Date = \(dateReleve.stringLongDate) ")
        print("  - Nb de points acquis       = \(nbPoints) ")
        print("  - Nb de points acquis / an  = \(pointsParAn)")
        print("  Calcul situation future:")
        print("  - Nombre de points projetés = \(pension.projectedNbOfPoints)")
        print("  Calcul du taux:")
        print("  - Taux de base avant majoration = \(coefMinoration*100.0) % (minoration de \(100.0 - coefMinoration*100.0) %)")
        print("  - Majoration pour enfants nés (plafonnée) = \(majorationPourEnfantNe.€String) soit \(majorationPourEnfantNe/pensionAvantMajorationPourEnfant*100.0) %")
        print("  - Majoration pour enfants à charge (2026) = \(majorationPourEnfantACharge.€String) soit \((coefEnfantACharge-1.0)*100.0) %")
        print("  - Majoration pour enfants retenue  (2026) = \(majorationPourEnfant.€String) soit \(majorationPourEnfant/pensionAvantMajorationPourEnfant*100.0) %")
        print("  - Majoration pour enfants retenue  (2030) = \(majorationPourEnfantNe.€String) soit \(majorationPourEnfantNe/pensionAvantMajorationPourEnfant*100.0) %")
        print("  Jusqu'à 2029:")
        print("  - Pension Brute annuelle (2026) = \(pension.pensionBrute.€String)")
        print("  - Pension Brute mensuelle(2026) = \((pension.pensionBrute / 12.0).€String)")
        print("  - Pension Nette annuelle (2026) = \(pension.pensionNette.€String)")
        print("  - Pension Nette mensuelle(2026) = \((pension.pensionNette / 12.0).€String)")
        print("  A partir de 2030:")
        print("  - Pension Brute annuelle (2030) = \(pension2030plus.pensionBrute.€String)")
        print("  - Pension Brute mensuelle(2030) = \((pension2030plus.pensionBrute / 12.0).€String)")
        print("  - Pension Nette annuelle (2030) = \(pension2030plus.pensionNette.€String)")
        print("  - Pension Nette mensuelle(2030) = \((pension2030plus.pensionNette / 12.0).€String)")

        //  CAS LIONEL SANS CHOMAGE JUSQU'A 62 ANS:
        //  Situation de référence (général):
        //  - Date = 31 décembre 2020
        //  - SAM  = 37 054 €
        //  - Nombre de trimestre acquis = 139
        //  Situation de référence (AGIRC-ARCCO)
        //  - Date = 31 décembre 2020
        //  - Nb de points acquis       = 19484
        //  - Nb de points acquis / an  = 789
        //  Calcul situation future:
        //  - Nombre de points projetés = 24020
        //  Calcul du taux:
        //  - Taux de base avant majoration = 93.0 % (minoration de 7.0 %)
        //  - Majoration pour enfants nés (plafonnée) = 2 072 € soit 7.293962913109368 %
        //  - Majoration pour enfants à charge (2026) = 2 840 € soit 10.000000000000009 %
        //  - Majoration pour enfants retenue  (2026) = 2 840 € soit 10.000000000000009 %
        //  - Majoration pour enfants retenue  (2030) = 2 072 € soit 7.293962913109368 %
        //  Jusqu'à 2029:
        //  - Pension Brute annuelle (2026) = 31 241 €
        //  - Pension Brute mensuelle(2026) = 2 603 € (M@rel = 2 424 €) écart = -179 €
        //  - Pension Nette annuelle (2026) = 28 086 €
        //  - Pension Nette mensuelle(2026) = 2 341 € (M@rel = 2 181 €) écart = -160 €
        //  A partir de 2030:
        //  - Pension Brute annuelle (2030) = 29 272 €
        //  - Pension Brute mensuelle(2030) = 2 439 €
        //  - Pension Nette annuelle (2030) = 26 316 €
        //  - Pension Nette mensuelle(2030) = 2 193 €
    }
    
    func test_cas_lionel_avec_chomage_62_ans() throws {
        let birthDate = self.date(year: 1964, month: 9, day: 22)
        let nbTrimestreAcquis = 139
        let sam               = 37054.0
        let atEndOf     = 2020
        let nbPoints    = 19484
        let pointsParAn = 789
        
        // dernier relevé connu des caisses de retraite
        let lastKnownSituation = RegimeGeneralSituation(atEndOf           : atEndOf,
                                                        nbTrimestreAcquis : nbTrimestreAcquis,
                                                        sam               : sam)
        let lastAgircKnownSituation = RegimeAgircSituation(atEndOf : atEndOf,
                                                           nbPoints    : nbPoints,
                                                           pointsParAn : pointsParAn)
        
        // Cessation d'activité à fin 2021 (PSE)
        let dateOfRetirement = lastDayOf(year: 2021)
        
        // Fin d'indemnisation après 3 ans de chômage
        let dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        
        // Liquidation de la pension à 62 ans + ce qu'il faut pour acquérir le dernier trimestre plein
        let dateOfPensionLiquid = (62.years + 10.days).from(birthDate)!

        // valeur du point
        let valeurDuPoint = RegimeAgircTest.regimeAgirc.valeurDuPoint
        XCTAssertEqual(1.2714, valeurDuPoint)
        
        /// Projection du nombre de points Agirc sur la base du dernier relevé de points et de la prévision de carrière future
        let projectedNumberOfPoints = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                                        .projectedNumberOfPoints(
                                                            lastAgircKnownSituation  : lastAgircKnownSituation,
                                                            dateOfRetirement         : dateOfRetirement,
                                                            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc),
                                                    "Failed projectedNumberOfPoints")
        let dateReleve = lastDayOf(year: atEndOf)
        let delta = Date.calendar.dateComponents([.year, .month, .day],
                                                 from: dateReleve,
                                                 to  : dateOfEndOfUnemployAlloc)
        let nbPointsAdded =
            delta.year! * pointsParAn +
            Int((delta.month!.double() / 12.0) * pointsParAn.double()) // mois pleins
        let nbPointTheory = lastAgircKnownSituation.nbPoints + nbPointsAdded
        XCTAssertEqual(nbPointTheory, projectedNumberOfPoints)
        
        /// Calcul le coefficient de minoration ou de majoration de la pension complémentaire selon
        let coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                            .coefMinorationMajoration(
                                                birthDate                : birthDate,
                                                lastKnownSituation       : lastKnownSituation,
                                                dateOfRetirement         : dateOfRetirement,
                                                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                                                dateOfPensionLiquid      : dateOfPensionLiquid,
                                                during                   : dateOfPensionLiquid.year))
        // 0.78: 20 trim manquant pour atteindre 67 ans
        // 0.92:  8 trim manquant pour le taux plein à 63 ans et 9 mois
        let coefTheory = max(0.92, 0.78)
        XCTAssertEqual(coefTheory, coefMinoration)
        
        // calcul pension avant majoration
        let pensionAvantMajorationPourEnfant = projectedNumberOfPoints.double() * valeurDuPoint * coefMinoration
        print(pensionAvantMajorationPourEnfant)
        
        // Calcul de la majoration pour enfant nés
        let nbEnfantNe = 3
        let coefEnfantNe = RegimeAgircTest.regimeAgirc
            .coefMajorationPourEnfantNe(nbEnfantNe: nbEnfantNe)
        XCTAssertEqual(1.1, coefEnfantNe)
        // plafonnement
        let majorationPourEnfantNe = min(pensionAvantMajorationPourEnfant * (coefEnfantNe - 1.0),
                                         RegimeAgircTest.regimeAgirc.model.majorationPourEnfant.plafondMajoEnfantNe)
        XCTAssertEqual(majorationPourEnfantNe, RegimeAgircTest.regimeAgirc.model.majorationPourEnfant.plafondMajoEnfantNe)
        
        // Calcul de la majoration pour enfant à charge (non plafonnée)
        var nbEnfantACharge = 2 // 2 jusqu'en 2029, 1 en 2030, 0 ensuite
        let coefEnfantACharge = RegimeAgircTest.regimeAgirc
            .coefMajorationPourEnfantACharge(nbEnfantACharge: nbEnfantACharge)
        let majorationPourEnfantACharge = pensionAvantMajorationPourEnfant * (coefEnfantACharge - 1.0)
        XCTAssertEqual(1.1, coefEnfantACharge)
        
        // on retient la plus favorable des deux majorations
        let majorationPourEnfant = max(majorationPourEnfantNe, majorationPourEnfantACharge)
        
        // Pension = Nombre de points X Valeurs du point X Coefficient de minoration X Coefficient de majoration enfants
        let pensionBrute = pensionAvantMajorationPourEnfant + majorationPourEnfant
        var during = dateOfPensionLiquid.year // 2026
        let pension = try XCTUnwrap(RegimeAgircTest.regimeAgirc.pension(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        nbEnfantNe               : nbEnfantNe,
                                        nbEnfantACharge          : nbEnfantACharge,
                                        during                   : during))
        XCTAssertEqual(pension.projectedNbOfPoints, projectedNumberOfPoints)
        XCTAssertEqual(pension.coefMinoration, coefMinoration)
        XCTAssertEqual(pension.majorationPourEnfant, majorationPourEnfant)
        XCTAssertEqual(pension.pensionBrute, pensionBrute)
        
        nbEnfantACharge = 0 // 2 jusqu'en 2029, 1 en 2030, 0 ensuite
        during = 2030
        let coefReavluation = RegimeAgircTest.regimeAgirc.revaluationCoef(
            during              : during,
            dateOfPensionLiquid : dateOfPensionLiquid)
        let pensionBrute2030plus = (pensionAvantMajorationPourEnfant + majorationPourEnfantNe) * coefReavluation
        let pension2030plus = try XCTUnwrap(RegimeAgircTest.regimeAgirc.pension(
                                                lastAgircKnownSituation  : lastAgircKnownSituation,
                                                birthDate                : birthDate,
                                                lastKnownSituation       : lastKnownSituation,
                                                dateOfRetirement         : dateOfRetirement,
                                                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                                                dateOfPensionLiquid      : dateOfPensionLiquid,
                                                nbEnfantNe               : nbEnfantNe,
                                                nbEnfantACharge          : nbEnfantACharge,
                                                during                   : during))
        XCTAssertEqual(pension2030plus.projectedNbOfPoints, projectedNumberOfPoints)
        XCTAssertEqual(pension2030plus.coefMinoration, coefMinoration)
        XCTAssertEqual(pension2030plus.majorationPourEnfant, majorationPourEnfantNe)
        XCTAssertEqual(pension2030plus.pensionBrute, pensionBrute2030plus)
        
        print("CAS LIONEL SANS CHOMAGE JUSQU'A 62 ANS:")
        print("  Situation de référence (général):")
        print("  - Date = \(dateReleve.stringLongDate) ")
        print("  - SAM  = \(lastKnownSituation.sam.€String)")
        print("  - Nombre de trimestre acquis = \(nbTrimestreAcquis)")
        print("  Situation de référence (AGIRC-ARCCO:")
        print("  - Date = \(dateReleve.stringLongDate) ")
        print("  - Nb de points acquis       = \(nbPoints) ")
        print("  - Nb de points acquis / an  = \(pointsParAn)")
        print("  Calcul situation future:")
        print("  - Nombre de points projetés = \(pension.projectedNbOfPoints)")
        print("  Calcul du taux:")
        print("  - Taux de base avant majoration = \(coefMinoration*100.0) % (minoration de \(100.0 - coefMinoration*100.0) %)")
        print("  - Majoration pour enfants nés (plafonnée) = \(majorationPourEnfantNe.€String) soit \(majorationPourEnfantNe/pensionAvantMajorationPourEnfant*100.0) %")
        print("  - Majoration pour enfants à charge (2026) = \(majorationPourEnfantACharge.€String) soit \((coefEnfantACharge-1.0)*100.0) %")
        print("  - Majoration pour enfants retenue  (2026) = \(majorationPourEnfant.€String) soit \(majorationPourEnfant/pensionAvantMajorationPourEnfant*100.0) %")
        print("  - Majoration pour enfants retenue  (2030) = \(majorationPourEnfantNe.€String) soit \(majorationPourEnfantNe/pensionAvantMajorationPourEnfant*100.0) %")
        print("  Jusqu'à 2029:")
        print("  - Pension Brute annuelle (2026) = \(pension.pensionBrute.€String)")
        print("  - Pension Brute mensuelle(2026) = \((pension.pensionBrute / 12.0).€String)")
        print("  - Pension Nette annuelle (2026) = \(pension.pensionNette.€String)")
        print("  - Pension Nette mensuelle(2026) = \((pension.pensionNette / 12.0).€String)")
        print("  A partir de 2030:")
        print("  - Pension Brute annuelle (2030) = \(pension2030plus.pensionBrute.€String)")
        print("  - Pension Brute mensuelle(2030) = \((pension2030plus.pensionBrute / 12.0).€String)")
        print("  - Pension Nette annuelle (2030) = \(pension2030plus.pensionNette.€String)")
        print("  - Pension Nette mensuelle(2030) = \((pension2030plus.pensionNette / 12.0).€String)")
        
        // CAS LIONEL SANS CHOMAGE JUSQU'A 62 ANS:
        //   Situation de référence (général):
        //   - Date = 31 décembre 2020
        //   - SAM  = 37 054 €
        //   - Nombre de trimestre acquis = 139
        //   Situation de référence (AGIRC-ARCCO:
        //   - Date = 31 décembre 2020
        //   - Nb de points acquis       = 19484
        //   - Nb de points acquis / an  = 789
        //   Calcul situation future:
        //   - Nombre de points projetés = 22640 (M@rel = 22538)
        //   Calcul du taux:
        //   - Taux de base avant majoration = 92.0 % (minoration de 8.0 %) (M@rel = 14.50 %)
        //   - Majoration pour enfants nés (plafonnée) = 2 072 € soit 7.822674370620724 %
        //   - Majoration pour enfants à charge (2026) = 2 648 € soit 10.000000000000009 %
        //   - Majoration pour enfants retenue  (2026) = 2 648 € soit 10.000000000000009 %
        //   - Majoration pour enfants retenue  (2030) = 2 072 € soit 7.822674370620724 %
        //   Jusqu'à 2029:
        //   - Pension Brute annuelle (2026) = 29 130 €
        //   - Pension Brute mensuelle(2026) = 2 427 € (M@rel = 2 062 €) écart = -365 €
        //   - Pension Nette annuelle (2026) = 26 188 €
        //   - Pension Nette mensuelle(2026) = 2 182 € (M@rel = 1855 €) écart = -327 €
        //   A partir de 2030:
        //   - Pension Brute annuelle (2030) = 27 428 €
        //   - Pension Brute mensuelle(2030) = 2 286 €
        //   - Pension Nette annuelle (2030) = 24 658 €
        //   - Pension Nette mensuelle(2030) = 2 055 €
        
        // CAS LIONEL SANS CHOMAGE JUSQU'A 62 ANS:
        // (MAREL: ajout de trimestres pendant la période indemnisation seulement: 3 ans et non 5 ans):
        //   Situation de référence (général):
        //   - Date = 31 décembre 2020
        //   - SAM  = 37 054 €
        //   - Nombre de trimestre acquis = 139
        //   Situation de référence (AGIRC-ARCCO:
        //   - Date = 31 décembre 2020
        //   - Nb de points acquis       = 19484
        //   - Nb de points acquis / an  = 789
        //   Calcul situation future:
        //   - Nombre de points projetés = 22640 (M@rel = 22538)
        //   Calcul du taux:
        //   - Taux de base avant majoration = 85.5 % (minoration de 14.5 %) (M@rel = 14.50 %)
        //   - Majoration pour enfants nés (plafonnée) = 2 072 € soit 8.417380609322885 %
        //   - Majoration pour enfants à charge (2026) = 2 461 € soit 10.000000000000009 %
        //   - Majoration pour enfants retenue  (2026) = 2 461 € soit 10.000000000000009 %
        //   - Majoration pour enfants retenue  (2030) = 2 072 € soit 8.417380609322885 %
        //   Jusqu'à 2029:
        //   - Pension Brute annuelle (2026) = 27 072 €
        //   - Pension Brute mensuelle(2026) = 2 256 € (M@rel = 2 062 €) écart = -194 €
        //   - Pension Nette annuelle (2026) = 24 338 €
        //   - Pension Nette mensuelle(2026) = 2 028 € (M@rel = 1855 €) écart = -173 €
        //   A partir de 2030:
        //   - Pension Brute annuelle (2030) = 25 631 €
        //   - Pension Brute mensuelle(2030) = 2 136 € (M@rel = 2 062 €) écart = -74 €
        //   - Pension Nette annuelle (2030) = 23 042 €
        //   - Pension Nette mensuelle(2030) = 1 920 € (M@rel = 1855 €) écart = -65 €
    }

    // MARK: - FIN CAS REELS
    
    func test_date_Age_Minimum_Agirc() {
        let birthDate = self.date(year: 1964, month: 9, day: 22)
        let date      = RegimeAgircTest.regimeAgirc.dateAgeMinimumAgirc(birthDate: birthDate)
        XCTAssertNotNil(date)
        XCTAssertEqual(1964 + 57, date!.year)
        XCTAssertEqual(9, date!.month)
        XCTAssertEqual(22, date!.day)
    }
    
    func test_recherche_coef_De_Minoration_Avant_Age_Legal() {
        var coef: Double?
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 2)
        XCTAssertEqual(0.745, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 5)
        XCTAssertEqual(0.6925, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 10)
        XCTAssertEqual(0.605, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 15)
        XCTAssertEqual(0.5175, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: 20)
        XCTAssertEqual(0.43, coef)
    }
    
    func test_recherche_coef_De_Minoration_Apres_Age_Legal() {
        var coef: Double?
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 0,
            nbTrimPostAgeLegalMin       : 18)
        XCTAssertEqual(1.0, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 5,
            nbTrimPostAgeLegalMin       : 15)
        XCTAssertEqual(0.95, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 10,
            nbTrimPostAgeLegalMin       : 14)
        XCTAssertEqual(0.94, coef)
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 19,
            nbTrimPostAgeLegalMin       : 8)
        XCTAssertEqual(0.88, coef)
        // liquidation à 62 ans
        coef = RegimeAgircTest.regimeAgirc.coefDeMinorationApresAgeLegal(
            nbTrimManquantPourTauxPlein : 7,
            nbTrimPostAgeLegalMin       : 0)
        XCTAssertEqual(max(0.93, 0.78), coef)
    }
    
    func test_projected_Number_Of_Points_sans_chomage() throws {
        let atEndOf     = 2020
        let nbPoints    = 19484
        let pointsParAn = 789
        var lastAgircKnownSituation  : RegimeAgircSituation
        var dateOfRetirement         : Date
        var nbPointsFuturs : Int
        var nbPointTheory  : Int
        
        // pas de période de chômage
        lastAgircKnownSituation = RegimeAgircSituation(atEndOf     : atEndOf,
                                                       nbPoints    : nbPoints,
                                                       pointsParAn : pointsParAn)
        dateOfRetirement = date(year: 2022, month: 1, day: 1)
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                        .projectedNumberOfPoints(
                                            lastAgircKnownSituation  : lastAgircKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil),
                                       "Failed projectedNumberOfPoints")
        nbPointTheory = lastAgircKnownSituation.nbPoints +
            (2021 - atEndOf) * lastAgircKnownSituation.pointsParAn
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
        
        // date de cessation d'activité antérieure à la date du dernier relevé de points
        dateOfRetirement = date(year: 2018, month: 1, day: 1)
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                        .projectedNumberOfPoints(
                                            lastAgircKnownSituation  : lastAgircKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil))
        nbPointTheory = lastAgircKnownSituation.nbPoints
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
    }
    
    func test_calcul_projected_Number_Of_Points_avec_chomage() throws {
        let atEndOf     = 2020
        let nbPoints    = 19484
        let pointsParAn = 789
        var lastAgircKnownSituation  : RegimeAgircSituation
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date!
        var nbPointsFuturs : Int
        var nbPointTheory  : Int
        
        // avec période de chômage
        lastAgircKnownSituation = RegimeAgircSituation(atEndOf     : atEndOf,
                                                       nbPoints    : nbPoints,
                                                       pointsParAn : pointsParAn)
        dateOfRetirement         = date(year : 2022, month : 1, day : 1)
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                        .projectedNumberOfPoints(
                                            lastAgircKnownSituation  : lastAgircKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc))
        nbPointTheory = lastAgircKnownSituation.nbPoints +
            (2021 - atEndOf) * lastAgircKnownSituation.pointsParAn +
            (3) * lastAgircKnownSituation.pointsParAn
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
        
        dateOfRetirement         = date(year : atEndOf, month : 1, day : 1)
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                        .projectedNumberOfPoints(
                                            lastAgircKnownSituation  : lastAgircKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc))
        nbPointTheory = lastAgircKnownSituation.nbPoints +
            (3 - 1) * lastAgircKnownSituation.pointsParAn
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
        
        // date de fin de chomage antérieure à la date du dernier relevé de points
        dateOfRetirement = date(year: 2014, month: 1, day: 1)
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        nbPointsFuturs = try XCTUnwrap(RegimeAgircTest.regimeAgirc
                                        .projectedNumberOfPoints(
                                            lastAgircKnownSituation  : lastAgircKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc))
        nbPointTheory = lastAgircKnownSituation.nbPoints
        XCTAssertEqual(nbPointTheory, nbPointsFuturs)
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_annee_taux_plein() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
        //     => pas de coef de réduction permanent
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 139, // taux plein à 62 ans + 9 mois
                                                    sam               : 0)
        dateOfRetirement    = (62.years + 9.months + 10.days).from(birthDate)! // fin d'activité salarié > 62 ans + 9 mois
        dateOfPensionLiquid = (62.years + 9.months + 10.days).from(birthDate)!  // liquidtation > 62 ans + 9 mois
        // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
        //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
        for during in (dateOfPensionLiquid.year)...min(birthDate.year + 66, (dateOfPensionLiquid.year + 3)) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            // pas de réduction de pension au-delà de 67 ans
            coefTheory = 0.9
            XCTAssertEqual(coefTheory, coefMinoration)
        }

        // (2) on a dépassé l'âge d'obtention du taux plein légal (67 ans)
        //     => taux plein
        for during in (birthDate.year + 67)...(birthDate.year + 90) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            // pas de réduction de pension au-delà de 67 ans
            coefTheory = 1.0
            XCTAssertEqual(coefTheory, coefMinoration)
        }
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_annee_taux_plein_plus_1() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
        //     => pas de coef de réduction permanent
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 139, // taux plein à 62 ans + 9 mois
                                                    sam               : 0)
        dateOfRetirement    = (62.years + 9.months + 10.days + 1.years).from(birthDate)! // fin d'activité salarié > 64 ans + 9 mois
        dateOfPensionLiquid = (62.years + 9.months + 10.days + 1.years).from(birthDate)!  // liquidtation > 64 ans + 9 mois
        
        //  (2)   => taux plein
        for during in (dateOfPensionLiquid.year)...(birthDate.year + 90) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            coefTheory = 1.0
            XCTAssertEqual(coefTheory, coefMinoration)
        }
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_annee_taux_plein_plus_2() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var during                   : Int
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
        //     => pas de coef de réduction permanent
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 139, // taux plein à 62 ans + 9 mois
                                                    sam               : 0)
        dateOfRetirement    = (62.years + 9.months + 10.days + 2.years).from(birthDate)! // fin d'activité salarié > 64 ans + 9 mois
        dateOfPensionLiquid = (62.years + 9.months + 10.days + 2.years).from(birthDate)!  // liquidtation > 64 ans + 9 mois
        
        // (2) l'année suivant la date d'obtention du taux plein légal (et avant 67 ans)
        //     => taux plein majoré de 10% pendant 1 an
        during = dateOfPensionLiquid.year
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        //     => taux plein majoré de 10% pendant 1 an
        coefTheory = 1.1
        XCTAssertEqual(coefTheory, coefMinoration)
        during = min(dateOfPensionLiquid.year + 1, birthDate.year + 66)
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        //     => taux plein majoré de 10% pendant 1 an
        coefTheory = 1.1
        XCTAssertEqual(coefTheory, coefMinoration)
        
        // (2) ensuite
        //     => taux plein
        for during in (dateOfPensionLiquid.year + 2)...(birthDate.year + 90) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            // pas de réduction de pension au-delà de 67 ans
            coefTheory = 1.0
            XCTAssertEqual(coefTheory, coefMinoration)
        }
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_annee_taux_plein_plus_3() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var during                   : Int
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
        //     => pas de coef de réduction permanent
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 139, // taux plein à 62 ans + 9 mois
                                                    sam               : 0)
        dateOfRetirement    = (62.years + 9.months + 10.days + 3.years).from(birthDate)! // fin d'activité salarié > 64 ans + 9 mois
        dateOfPensionLiquid = (62.years + 9.months + 10.days + 3.years).from(birthDate)!  // liquidtation > 64 ans + 9 mois
        
        // (2) l'année suivant la date d'obtention du taux plein légal (et avant 67 ans)
        //     => taux plein majoré de 10% pendant 1 an
        during = dateOfPensionLiquid.year
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        //     => taux plein majoré de 20% pendant 1 an
        coefTheory = 1.2
        XCTAssertEqual(coefTheory, coefMinoration)
        during = min(dateOfPensionLiquid.year + 1, birthDate.year + 66)
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        //     => taux plein majoré de 20% pendant 1 an
        coefTheory = 1.2
        XCTAssertEqual(coefTheory, coefMinoration)
        
        // (2) ensuite
        //     => taux plein
        for during in (min(dateOfPensionLiquid.year + 1, birthDate.year + 66)+1)...(birthDate.year + 90) {
            coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                            birthDate                : birthDate,
                                            lastKnownSituation       : lastKnownSituation,
                                            dateOfRetirement         : dateOfRetirement,
                                            dateOfEndOfUnemployAlloc : nil,
                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                            during                   : during))
            // pas de réduction de pension au-delà de 67 ans
            coefTheory = 1.0
            XCTAssertEqual(coefTheory, coefMinoration)
        }
    }
    
    func test_calcul_coef_minoration_majoration_liquidation_avant_age_legal() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var during                   : Int
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation avant l'age minimul de liquidation de la pension AGIRC
        //     => pas de résultat
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : 0)
        dateOfRetirement    = (55.years + 10.days).from(birthDate)!
        dateOfPensionLiquid = (55.years + 10.days).from(birthDate)!
        during = dateOfPensionLiquid.year

        XCTAssertNil(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                        birthDate                : birthDate,
                        lastKnownSituation       : lastKnownSituation,
                        dateOfRetirement         : dateOfRetirement,
                        dateOfEndOfUnemployAlloc : nil,
                        dateOfPensionLiquid      : dateOfPensionLiquid,
                        during                   : during))

        // (1) Liquidation à l'age minimul de liquidation de la pension AGIRC
        //     => coef de réduction permanent
        dateOfRetirement    = (57.years + 10.days).from(birthDate)!
        dateOfPensionLiquid = (57.years + 10.days).from(birthDate)!
        during = dateOfPensionLiquid.year

        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        coefTheory = 0.43
        XCTAssertEqual(coefTheory, coefMinoration)
    }

    func test_calcul_coef_minoration_majoration_liquidation_apres_age_legal_avant_taux_plein() throws {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var during                   : Int
        var coefMinoration           : Double
        var coefTheory               : Double
        
        birthDate = date(year : 1964, month : 9, day : 22)
        
        // (1) Liquidation après l'age légal de liquidation de la pension du régime génarle
        //     Mais sans avoir ne nb de trimestre requis pour avoir la pension générale au taux plein
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : 0)

        // 1 trimestres manquant
        dateOfRetirement    = (63.years + 8.months + 10.days).from(birthDate)!
        dateOfPensionLiquid = (63.years + 8.months + 10.days).from(birthDate)!
        during = dateOfPensionLiquid.year
        
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        coefTheory = 0.99 // 1% de décote = 0.99
        XCTAssertEqual(coefTheory, coefMinoration)

        // 3 trimestres manquant
        dateOfRetirement    = (63.years + 10.days).from(birthDate)!
        dateOfPensionLiquid = (63.years + 10.days).from(birthDate)!
        during = dateOfPensionLiquid.year
        
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        coefTheory = 0.97 // 3% de décote = 0.97
        XCTAssertEqual(coefTheory, coefMinoration)

        // 4 + 3 = 7 trimestres manquant
        dateOfRetirement    = (62.years + 10.days).from(birthDate)!
        dateOfPensionLiquid = (62.years + 10.days).from(birthDate)!
        during = dateOfPensionLiquid.year
        
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        coefTheory = 0.93 // 7% de décote = 0.93
        XCTAssertEqual(coefTheory, coefMinoration)
        
        // cas:
        //  - fin d'activité salarié    : fin 2021
        //  - fin d'indemnité chômage   : 3 ans plus tard
        //  - liquidation de la pension : à 62 ans
        // à 62 ans pile il manquera 8 trimestres
        dateOfRetirement             = date(year : 2022, month : 1, day : 1)
        let dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        dateOfPensionLiquid          = (62.years).from(birthDate)!
        during = dateOfPensionLiquid.year
        
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        coefTheory = 0.92 // 8% de décote = 0.92
        XCTAssertEqual(coefTheory, coefMinoration)
        
        // (63.75 - 57.25) * 4 = 26 trimestres manquant > 20
        dateOfRetirement    = date(year : 2022, month : 1, day : 1)
        dateOfPensionLiquid = (62.years + 10.days).from(birthDate)!
        during              = dateOfPensionLiquid.year
        
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        coefTheory = 0.78 // décote maximale 22% = 0.78
        XCTAssertEqual(coefTheory, coefMinoration)

        // (63.75 - 60.25) * 4 = 14 trimestres manquant
        dateOfRetirement    = date(year : 2022, month : 1, day : 1)
        dateOfRetirement    = 3.years.from(dateOfRetirement)!
        dateOfPensionLiquid = (62.years + 10.days).from(birthDate)!
        during = dateOfPensionLiquid.year
        
        coefMinoration = try XCTUnwrap(RegimeAgircTest.regimeAgirc.coefMinorationMajoration(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        during                   : during))
        coefTheory = 0.855 // décote maximale 14.5% = 0.855
        XCTAssertEqual(coefTheory, coefMinoration)    }
    
    func test_calcul_coef_majoration_pour_enfant_ne() {
        var nbEnfantNe      : Int
        var coef            : Double

        nbEnfantNe      = -1
        coef = RegimeAgircTest.regimeAgirc.coefMajorationPourEnfantNe(
            nbEnfantNe: nbEnfantNe)
        XCTAssertEqual(1.0, coef)

        nbEnfantNe      = 2
        coef = RegimeAgircTest.regimeAgirc.coefMajorationPourEnfantNe(
            nbEnfantNe: nbEnfantNe)
        XCTAssertEqual(1.0, coef)

        nbEnfantNe      = 3
        coef = RegimeAgircTest.regimeAgirc.coefMajorationPourEnfantNe(
            nbEnfantNe: nbEnfantNe)
        XCTAssertEqual(1.1, coef)

        nbEnfantNe      = 10
        coef = RegimeAgircTest.regimeAgirc.coefMajorationPourEnfantNe(
            nbEnfantNe: nbEnfantNe)
        XCTAssertEqual(1.1, coef)
    }

    func test_calcul_majoration_pour_enfant_ne() {
        var pensionBrute : Double
        var majoration   : Double
        var nbEnfantNe   : Int

        nbEnfantNe = 0
        pensionBrute = 10_000
        majoration = RegimeAgircTest.regimeAgirc.majorationPourEnfantNe(
            pensionBrute: pensionBrute, nbEnfantNe: nbEnfantNe)
        XCTAssertEqual(0, majoration)

        nbEnfantNe = 3
        pensionBrute = 10_000
        majoration = RegimeAgircTest.regimeAgirc.majorationPourEnfantNe(
            pensionBrute: pensionBrute, nbEnfantNe: nbEnfantNe)
        XCTAssert(majoration.isApproximatelyEqual(to: 1000))

        nbEnfantNe = 3
        pensionBrute = 30_000
        majoration = RegimeAgircTest.regimeAgirc.majorationPourEnfantNe(
            pensionBrute: pensionBrute, nbEnfantNe: nbEnfantNe)
        XCTAssertEqual(2071.58, majoration)
    }

    func test_calcul_coef_majoration_pour_enfant_a_charge() {
        var nbEnfantACharge : Int
        var coef            : Double

        nbEnfantACharge = -1
        coef = RegimeAgircTest.regimeAgirc.coefMajorationPourEnfantACharge(
            nbEnfantACharge : nbEnfantACharge)
        XCTAssertEqual(1.0, coef)

        nbEnfantACharge = 1
        coef = RegimeAgircTest.regimeAgirc.coefMajorationPourEnfantACharge(
            nbEnfantACharge : nbEnfantACharge)
        XCTAssertEqual(1.05, coef)

        nbEnfantACharge = 2
        coef = RegimeAgircTest.regimeAgirc.coefMajorationPourEnfantACharge(
            nbEnfantACharge : nbEnfantACharge)
        XCTAssertEqual(1.1, coef)

        nbEnfantACharge = 3
        coef = RegimeAgircTest.regimeAgirc.coefMajorationPourEnfantACharge(
            nbEnfantACharge : nbEnfantACharge)
        XCTAssertEqual(1.15, coef)
    }

    func test_calcul_pension() throws {
        var lastAgircKnownSituation  : RegimeAgircSituation
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date?
        var dateOfPensionLiquid      : Date
        var nbEnfantNe               : Int
        var nbEnfantACharge          : Int
        var during                   : Int?
        var nbPointTheory            : Int
        var coefMinorationTheory     : Double
        var pensionBruteTheory       : Double

        birthDate          = date(year: 1964, month: 9, day: 22)
        let sam            = 36698.0
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : sam)
        lastAgircKnownSituation = RegimeAgircSituation(atEndOf     : 2018,
                                                       nbPoints    : 17907,
                                                       pointsParAn : 788)
        // cas:
        //  - fin d'activité salarié    : fin 2021
        //  - fin d'indemnité chômage   : 3 ans plus tard
        //  - liquidation de la pension : à 62 ans
        dateOfRetirement = date(year : 2022, month : 1, day : 1) // fin d'activité salarié
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement) // fin d'indemnisation chomage 3 ans plus tard
        dateOfPensionLiquid      = 62.years.from(birthDate)! // liquidation à 62 ans
        nbEnfantNe               = 3
        nbEnfantACharge          = 2
        during = dateOfPensionLiquid.year
        let pension = try XCTUnwrap(RegimeAgircTest.regimeAgirc.pension(
                                        lastAgircKnownSituation  : lastAgircKnownSituation,
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                                        dateOfPensionLiquid      : dateOfPensionLiquid,
                                        nbEnfantNe               : nbEnfantNe,
                                        nbEnfantACharge          : nbEnfantACharge,
                                        during                   : during))
        coefMinorationTheory = 0.92  // voir autre test
        XCTAssertEqual(coefMinorationTheory, pension.coefMinoration)

        nbPointTheory = lastAgircKnownSituation.nbPoints +
            (2021 - 2018) * lastAgircKnownSituation.pointsParAn +
            (3) * lastAgircKnownSituation.pointsParAn // voir autre test
        XCTAssertEqual(nbPointTheory, pension.projectedNbOfPoints)
        
        let majoration = max(2071.58, 0.05 * Double(nbEnfantACharge) * Double(nbPointTheory) * 1.2714 * coefMinorationTheory)
        XCTAssert(majoration.isApproximatelyEqual(to: pension.majorationPourEnfant))

        // Pension = Nombre de points X Valeurs du point X Coefficient de minoration + majoration pour enfants
        pensionBruteTheory = Double(nbPointTheory) * 1.2714 * coefMinorationTheory + majoration
        XCTAssertEqual(pensionBruteTheory, pension.pensionBrute)
    }
}  // swiftlint:disable:this file_length
