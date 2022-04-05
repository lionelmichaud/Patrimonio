//
//  RegimeGeneralTest.swift
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

class RegimeGeneralTest: XCTestCase { // swiftlint:disable:this type_body_length
    
    func isApproximatelyEqual(_ x: Double, _ y: Double) -> Bool {
        if x == 0 {
            return abs((x-y)) < 0.0001
        } else {
            return abs((x-y)) / x < 0.0001
        }
    }
    
    static var regimeGeneral: RegimeGeneral!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        let model = RegimeGeneral.Model(fromFile   : "RegimeGeneralModel.json",
                                        fromBundle : Bundle.module)
        RegimeGeneralTest.regimeGeneral = RegimeGeneral(model: model)
        
        // inject dependency for tests
        RegimeGeneralTest.regimeGeneral.setSocioEconomyModel(
            SocioEconomy.Model(fromFile   : "SocioEconomyModelConfig.json",
                               fromBundle : Bundle.module)
                .initialized())
        RegimeGeneralTest.regimeGeneral.setNetRegimeGeneralProvider(
            Fiscal
                .Model(fromFile   : "FiscalModelConfig.json",
                       fromBundle : Bundle.module)
                .initialized()
                .pensionTaxes)
    }
    
    func date(year: Int, month: Int, day: Int) -> Date {
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : year,
                                         month    : month,
                                         day      : day)
        return Date.calendar.date(from: dateRefComp)!
    }
    
    // MARK: Tests
    
    func test_saving_to_test_bundle() throws {
        RegimeGeneralTest.regimeGeneral.saveAsJSON(toFile               : "RegimeGeneralModel.json",
                                                   toBundle             : Bundle.module,
                                                   dateEncodingStrategy : .iso8601,
                                                   keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func test_pension_devaluation_rate() {
        XCTAssertEqual(1.0, RegimeGeneralTest.regimeGeneral.devaluationRate)
    }
    
    func test_nb_Trim_Additional() {
        XCTAssertEqual(0, RegimeGeneralTest.regimeGeneral.nbTrimAdditional)
    }
    
    func test_calcul_revaluation_Coef() {
        let dateOfPensionLiquid : Date! = 10.years.ago
        let thisYear = CalendarCst.thisYear
        
        let coef = RegimeGeneralTest.regimeGeneral.revaluationCoef(during: thisYear,
                                                                   dateOfPensionLiquid: dateOfPensionLiquid)
        XCTAssertEqual(pow((1.0 + -1.0/100.0), 10.0), coef)
    }
    
    func test_recherche_nb_Trim_Acquis_Apres_Period_Chomage_Non_Indemnise() {
        var nbTrimDejaCotises     : Int
        var ageEnFinIndemnisation : Int
        var nb                    : Int?
        
        nbTrimDejaCotises     = 19
        ageEnFinIndemnisation = 50
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(
            nbTrimestreAcquis: nbTrimDejaCotises,
            ageAtEndOfUnemployementAlloc: ageEnFinIndemnisation)
        XCTAssertEqual(4, nb)
        
        nbTrimDejaCotises     = 90
        ageEnFinIndemnisation = 50
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(
            nbTrimestreAcquis: nbTrimDejaCotises,
            ageAtEndOfUnemployementAlloc: ageEnFinIndemnisation)
        XCTAssertEqual(4, nb)
        
        nbTrimDejaCotises     = 90
        ageEnFinIndemnisation = 56
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(
            nbTrimestreAcquis: nbTrimDejaCotises,
            ageAtEndOfUnemployementAlloc: ageEnFinIndemnisation)
        XCTAssertEqual(20, nb)
        
        nbTrimDejaCotises     = 19
        ageEnFinIndemnisation = 56
        nb = RegimeGeneralTest.regimeGeneral.nbTrimAcquisApresPeriodNonIndemnise(
            nbTrimestreAcquis: nbTrimDejaCotises,
            ageAtEndOfUnemployementAlloc: ageEnFinIndemnisation)
        XCTAssertEqual(4, nb)
    }
    
    func test_recherche_age_Taux_Plein_Legal() {
        var age: Int?
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1948)
        XCTAssertEqual(61, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1953)
        XCTAssertEqual(62, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1956)
        XCTAssertEqual(64, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1963)
        XCTAssertEqual(66, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1964)
        XCTAssertEqual(67, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1967)
        XCTAssertEqual(67, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1968)
        XCTAssertEqual(67, age)
        age = RegimeGeneralTest.regimeGeneral.ageTauxPleinLegal(birthYear: 1980)
        XCTAssertEqual(71, age)
    }
    
    func test_recherche_duree_De_Reference() {
        var duree: Int?
        duree = RegimeGeneralTest.regimeGeneral.dureeDeReference(birthYear: 1963)
        XCTAssertEqual(168, duree)
        duree = RegimeGeneralTest.regimeGeneral.dureeDeReference(birthYear: 1964)
        XCTAssertEqual(169, duree)
        duree = RegimeGeneralTest.regimeGeneral.dureeDeReference(birthYear: 1968)
        XCTAssertEqual(170, duree)
        duree = RegimeGeneralTest.regimeGeneral.dureeDeReference(birthYear: 1980)
        XCTAssertEqual(172, duree)
    }
    
    // MARK: - CAS REELS A VERIFIER AVEC MAREL
    
    func test_cas_lionel_sans_chomage_62_ans() throws {
        let birthDate         = date(year : 1964, month : 9, day : 22)
        let nbTrimestreAcquis = 139
        let atEndOf           = 2020
        let sam               = 37054.0
        var lastKnownSituation  : RegimeGeneralSituation
        var dateOfPensionLiquid : Date
        
        // dernier relevé connu des caisses de retraite
        let dateReleve = lastDayOf(year: atEndOf) 
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : atEndOf,
                                                    nbTrimestreAcquis : nbTrimestreAcquis,
                                                    sam               : sam)
        let dateAgeMinimumLegal = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                                    .dateAgeMinimumLegal(birthDate: birthDate),
                                                "Cas réel avec chomage: dateAgeMinimumLegal failed")
        // Cessation d'activité à 62 ans + ce qu'il faut pour acquérir le dernier trimestre plein
        dateOfPensionLiquid = (62.years + 10.days).from(birthDate)!
        // nombre de trimestre restant à acquérir
        let delta = Date.calendar.dateComponents([.year, .month, .day],
                                                 from: dateReleve,
                                                 to  : dateOfPensionLiquid)
        let nbTrim = delta.year! * 4 + delta.month! / 3
        
        /// Durée d'assurance
        
        let dureeAssurance = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                            .dureeAssurance(
                                                birthDate                : birthDate,
                                                lastKnownSituation       : lastKnownSituation,
                                                dateOfRetirement         : dateOfPensionLiquid,
                                                dateOfEndOfUnemployAlloc : nil),
                                           "Cas réel sans chomage: dureeAssurance failed")
        let theory = nbTrimestreAcquis + nbTrim // 162
        XCTAssertEqual(162, theory)
        XCTAssertEqual(162, dureeAssurance.plafonne, "Cas réel sans chomage: dureeAssurance failed")
        XCTAssertEqual(162, dureeAssurance.deplafonne, "Cas réel sans chomage: dureeAssurance failed")
        
        /// Durée d'assurance de référence
        let dureeDeReference = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                                .dureeDeReference(birthYear: birthDate.year),
                                             "Cas réel sans chomage: dureeDeReference failed")
        XCTAssertEqual(169, dureeDeReference, "Cas réel sans chomage: dureeDeReference failed")
        
        /// Age taux plein légal
        let ageTauxPlein = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                            .ageTauxPleinLegal(birthYear: birthDate.year),
                                         "Cas réel sans chomage: ageTauxPlein failed")
        XCTAssertEqual(67, ageTauxPlein, "Cas réel sans chomage: ageTauxPlein failed")
        
        /// Calcul la décote (-) ou surcote (+) en nmbre de trimestre
        let nbTrimPluMoins = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                            .nbTrimestreSurDecote(birthDate           : birthDate,
                                                                  dureeAssurance      : dureeAssurance.plafonne,
                                                                  dureeDeReference    : dureeDeReference,
                                                                  dateOfPensionLiquid : dateOfPensionLiquid),
                                           "Cas réel sans chomage: nbTrimestreSurDecote failed")
        XCTAssertEqual(-7, nbTrimPluMoins, "Cas réel sans chomage: nbTrimestreSurDecote failed")
        
        /// Calcul du taux de reversion en tenant compte d'une décote ou d'une surcote éventuelle
        let taux = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                    .tauxDePension(birthDate           : birthDate,
                                                   dureeAssurance      : dureeAssurance.plafonne,
                                                   dureeDeReference    : dureeDeReference,
                                                   dateOfPensionLiquid : dateOfPensionLiquid),
                                 "Cas réel sans chomage: tauxDePension failed")
        let tauxTheory = 50.0 - 7 * 0.625
        XCTAssertEqual(45.625, tauxTheory)
        XCTAssertEqual(45.625, taux, "Cas réel sans chomage: tauxDePension failed")
        
        /// Calcul du coefficient de majoration de la pension pour enfants nés
        let majorationEnfant = RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 3)
        XCTAssertEqual(10.0, majorationEnfant)
        
        /// Pension = Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        let (pensionBrut, pensionNet) = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                                        .pension(
                                                            birthDate                : birthDate,
                                                            dateOfRetirement         : dateOfPensionLiquid,
                                                            dateOfEndOfUnemployAlloc : nil,
                                                            dateOfPensionLiquid      : dateOfPensionLiquid,
                                                            lastKnownSituation       : lastKnownSituation,
                                                            nbEnfantNe               : 3,
                                                            during                   : nil),
                                                      "Cas réel sans chomage: pension failed")
        let brutTheory = lastKnownSituation.sam * (taux / 100.0) * (1.0 + majorationEnfant/100) * (dureeAssurance.plafonne.double() / dureeDeReference.double())
        XCTAssertTrue(isApproximatelyEqual(brutTheory, pensionBrut), "Cas réel sans chomage: pension failed")
        
        print("CAS LIONEL SANS CHOMAGE JUSQU'A 62 ANS:")
        print("  Situation de référence:")
        print("  - Date = \(dateReleve.stringLongDate) ")
        print("  - SAM  = \(lastKnownSituation.sam.€String)")
        print("  - Nombre de trimestre acquis = \(nbTrimestreAcquis)")
        print("  Situation professionnelle:")
        print("  - Date légale liquidation de pension = \(dateAgeMinimumLegal.stringLongDate)")
        print("  Calcul des nb de trimestres:")
        print("  - Nb trim restant à acquérir après date réf = \(nbTrim)")
        print("  - Nb trim manquants                         = \(nbTrimPluMoins)")
        print("  - Durée Assurance    = \(dureeAssurance.plafonne)")
        print("  - Durée de référence = \(dureeDeReference)")
        print("  Calcul du taux:")
        print("  - Taux de base avant majoration = \(taux) % (minoration de \(50.0 - taux) %)")
        print("  - Majoration pour enfants       = \(majorationEnfant) %")
        print("  Pension Brute annuelle  = \(pensionBrut.€String) = SAM x Taux x Majoration x (Durée Assurance / Durée de référence)")
        print("  Pension Brute mensuelle = \((pensionBrut / 12.0).€String)")
        print("  Pension Nette annuelle  = \(pensionNet.€String)")
        print("  Pension Nette mensuelle = \((pensionNet / 12.0).€String)")

        // CAS LIONEL SANS CHOMAGE JUSQU'A 62 ANS:
        //  Situation de référence:
        //  - Date = 31 décembre 2020
        //  - SAM  = 37 054 €
        //  - Nombre de trimestre acquis = 139
        //  Situation professionnelle:
        //  - Date légale liquidation de pension = 22 septembre 2026
        //  Calcul des nb de trimestres:
        //  - Nb trim restant à acquérir après date réf = 23
        //  - Nb trim manquants                         = -7
        //  - Durée Assurance    = 162
        //  - Durée de référence = 169
        //  Calcul du taux:
        //  - Taux de base avant majoration = 45.625 % (minoration de 4.375 %)
        //  - Majoration pour enfants       = 10.0 %
        //  Pension Brute annuelle  = 17 826 € = SAM x Taux x Majoration x (Durée Assurance / Durée de référence)
        //  Pension Brute mensuelle = 1 486 € (M@rel = 1 504 €)
        //  Pension Nette annuelle  = 16 204 €
        //  Pension Nette mensuelle = 1 350 € (M@rel = 1 367 €)  écart = +17 €
    }
    
    func test_cas_lionel_avec_chomage_62_ans() throws {
        let birthDate         = date(year : 1964, month : 9, day : 22)
        let nbTrimestreAcquis = 139
        let atEndOf           = 2020
        let sam               = 37054.0

        // dernier relevé connu des caisses de retraite
        let dateReleve = lastDayOf(year: atEndOf)
        let lastKnownSituation = RegimeGeneralSituation(atEndOf           : atEndOf,
                                                        nbTrimestreAcquis : nbTrimestreAcquis,
                                                        sam               : sam)
        // Cessation d'activité à fin 2021 (PSE)
        let dateOfRetirement = lastDayOf(year: 2021)
        
        // Fin d'indemnisation après 3 ans de chômage
        let dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)!
        
        // Liquidation de pension à 62 ans + ce qu'il faut pour acquérir le dernier trimestre plein
        let dateAgeMinimumLegal = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                                    .dateAgeMinimumLegal(birthDate: birthDate),
                                                "Cas réel avec chomage: dateAgeMinimumLegal failed")
        let date62ans = 62.years.from(birthDate)!
        XCTAssertEqual(date62ans, dateAgeMinimumLegal, "Cas réel avec chomage: dateAgeMinimumLegal failed")
        
        // nombre de trimestre restant à acquérir compte tenu de la situation professionnelle future
        //  = 3 ans d'ARE + 5 ans (+ de 55 ans et + de 20 ans de cotisation) = 8 x 4 = 32
        //  plafonné au nb de trimestres permettant d'atteindre 62 ans
        let deltaDeRefARetirement = Date.calendar.dateComponents([.year, .month, .day],
                                                                from: dateReleve,
                                                                to  : dateOfRetirement)
        let nbTrimDeRefARetirement = deltaDeRefARetirement.year! * 4 + deltaDeRefARetirement.month! / 3 // 4
        let deltaDeRetirementA62 = Date.calendar.dateComponents([.year, .month, .day],
                                                 from: dateOfRetirement,
                                                 to  : dateAgeMinimumLegal)
        let nbTrimDeRetirementA62 = deltaDeRetirementA62.year! * 4 + deltaDeRetirementA62.month! / 3 // 18
        let nbTrimApresRetirement = min(nbTrimDeRetirementA62, (3 + 5) * 4) // 18
        let nbTrim = nbTrimDeRefARetirement + nbTrimApresRetirement // 22
        
        /// Durée d'assurance
        
        let dureeAssurance = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                            .dureeAssurance(
                                                birthDate                : birthDate,
                                                lastKnownSituation       : lastKnownSituation,
                                                dateOfRetirement         : dateOfRetirement,
                                                dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc),
                                           "Cas réel avec chomage: dureeAssurance failed")
        let theory = nbTrimestreAcquis + nbTrim // 161 à 62 ans pile
        XCTAssertEqual(161, theory)
        XCTAssertEqual(161, dureeAssurance.plafonne, "Cas réel avec chomage: dureeAssurance failed")
        XCTAssertEqual(161, dureeAssurance.deplafonne, "Cas réel avec chomage: dureeAssurance failed")
        //dureeAssurance = (161, 161) et non pas 155 comme estimé par MAREL
        
        /// Durée d'assurance de référence
        let dureeDeReference = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                                .dureeDeReference(birthYear: birthDate.year),
                                             "Cas réel avec chomage: dureeDeReference failed")
        XCTAssertEqual(169, dureeDeReference, "Cas réel avec chomage: dureeDeReference failed")
        
        /// Age taux plein légal
        let ageTauxPlein = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                            .ageTauxPleinLegal(birthYear: birthDate.year),
                                         "Cas réel avec chomage: ageTauxPlein failed")
        XCTAssertEqual(67, ageTauxPlein, "Cas réel avec chomage: ageTauxPlein failed")
        
        /// Calcul la décote (-) ou surcote (+) en nmbre de trimestre
        let nbTrimPluMoins = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                            .nbTrimestreSurDecote(birthDate           : birthDate,
                                                                  dureeAssurance      : dureeAssurance.plafonne,
                                                                  dureeDeReference    : dureeDeReference,
                                                                  dateOfPensionLiquid : dateAgeMinimumLegal),
                                           "Cas réel avec chomage: nbTrimestreSurDecote failed")
        XCTAssertEqual(-8, nbTrimPluMoins, "Cas réel avec chomage: nbTrimestreSurDecote failed")
        
        /// Calcul du taux de reversion en tenant compte d'une décote ou d'une surcote éventuelle
        let taux = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                    .tauxDePension(birthDate           : birthDate,
                                                   dureeAssurance      : dureeAssurance.plafonne,
                                                   dureeDeReference    : dureeDeReference,
                                                   dateOfPensionLiquid : dateAgeMinimumLegal),
                                 "Cas réel avec chomage: tauxDePension failed")
        let tauxTheory = 50.0 - 8 * 0.625
        XCTAssertEqual(45.0, tauxTheory)
        XCTAssertEqual(45.0, taux, "Cas réel avec chomage: tauxDePension failed")
        
        /// Calcul du coefficient de majoration de la pension pour enfants nés
        let majorationEnfant = RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 3)
        XCTAssertEqual(10.0, majorationEnfant)
        
        /// Pension = Salaire annuel moyen x Taux de la pension x (Durée d'assurance du salarié au régime général / Durée de référence pour obtenir une pension à taux plein)
        let (pensionBrut, pensionNet) = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                                        .pension(
                                                            birthDate                : birthDate,
                                                            dateOfRetirement         : dateOfRetirement,
                                                            dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                                                            dateOfPensionLiquid      : dateAgeMinimumLegal,
                                                            lastKnownSituation       : lastKnownSituation,
                                                            nbEnfantNe               : 3,
                                                            during                   : nil),
                                                      "Cas réel avec chomage: pension failed")
        let brutTheory = lastKnownSituation.sam * (taux / 100.0) * (1.0 + majorationEnfant/100) * (dureeAssurance.plafonne.double() / dureeDeReference.double())
        print(brutTheory)
        XCTAssertTrue(isApproximatelyEqual(brutTheory, pensionBrut), "Cas réel avec chomage: pension failed")
        print("CAS LIONEL AVEC 3 ANS DE CHOMAGE:")
        print("  Situation de référence:")
        print("  - Date = \(dateReleve.stringLongDate) ")
        print("  - SAM  = \(lastKnownSituation.sam.€String)")
        print("  - Nombre de trimestre acquis = \(nbTrimestreAcquis)")
        print("  Situation professionnelle:")
        print("  - Date de cessation d'activité       = \(dateOfRetirement.stringLongDate)")
        print("  - Date de fin d'indemnisation        = \(dateOfEndOfUnemployAlloc.stringLongDate)")
        print("  - Date légale liquidation de pension = \(dateAgeMinimumLegal.stringLongDate)")
        print("  Calcul des nb de trimestres:")
        print("  - Nb trim restant à acquérir après date réf = \(nbTrim)")
        print("  - Nb trim manquants                         = \(nbTrimPluMoins)")
        print("  - Durée Assurance    = \(dureeAssurance.plafonne)")
        print("  - Durée de référence = \(dureeDeReference)")
        print("  Calcul du taux:")
        print("  - Taux de base avant majoration = \(taux) % (minoration de \(50.0 - taux) %)")
        print("  - Majoration pour enfants       = \(majorationEnfant) %")
        print("  Pension Brute annuelle  = \(pensionBrut.€String) = SAM x Taux x Majoration x (Durée Assurance / Durée de référence)")
        print("  Pension Brute mensuelle = \((pensionBrut / 12.0).€String)")
        print("  Pension Nette annuelle  = \(pensionNet.€String)")
        print("  Pension Nette mensuelle = \((pensionNet / 12.0).€String)")
        
        // CAS LIONEL AVEC 3 ANS DE CHOMAGE:
        //   Situation de référence:
        //   - Date = 31 décembre 2020
        //   - SAM  = 37 054 €
        //   - Nombre de trimestre acquis = 139
        //   Situation professionnelle:
        //   - Date de cessation d'activité       = 31 décembre 2021
        //   - Date de fin d'indemnisation        = 31 décembre 2024
        //   - Date légale liquidation de pension = 22 septembre 2026
        //   Calcul des nb de trimestres:
        //   - Nb trim restant à acquérir après date réf = 22
        //   - Nb trim manquants                         = -8
        //   - Durée Assurance    = 161
        //   - Durée de référence = 169
        //   Calcul du taux:
        //   - Taux de base avant majoration = 45.0 % (minoration de 5.0 %)
        //   - Majoration pour enfants       = 10.0 %
        //   Pension Brute annuelle  = 17 473 € = SAM x Taux x Majoration x (Durée Assurance / Durée de référence)
        //   Pension Brute mensuelle = 1 456 €
        //   Pension Nette annuelle  = 15 883 €
        //   Pension Nette mensuelle = 1 324 €
        //
        // CAS LIONEL AVEC 3 ANS DE CHOMAGE:
        // (MAREL: ajout de trimestres pendant la période indemnisation seulement: 3 ans et non 5 ans):
        //   Situation de référence:
        //   - Date = 31 décembre 2020
        //   - SAM  = 37 054 €
        //   - Nombre de trimestre acquis = 139
        //   Situation professionnelle:
        //   - Date de cessation d'activité       = 31 décembre 2021
        //   - Date de fin d'indemnisation        = 31 décembre 2024
        //   - Date légale liquidation de pension = 22 septembre 2026
        //   Calcul des nb de trimestres:
        //   - Nb trim restant à acquérir après date réf = 22
        //   - Nb trim manquants                         = -14
        //   - Durée Assurance    = 155
        //   - Durée de référence = 169
        //   Calcul du taux:
        //   - Taux de base avant majoration = 41.25 % (minoration de 8.75 %)
        //   - Majoration pour enfants       = 10.0 %
        //   Pension Brute annuelle  = 15 420 € = SAM x Taux x Majoration x (Durée Assurance / Durée de référence)
        //   Pension Brute mensuelle = 1 285 € (M@rel = 1 096 €) écart = -189 €
        //   Pension Nette annuelle  = 14 017 €
        //   Pension Nette mensuelle = 1 168 € (M@rel = 996 €) écart = -172 €
    }
    
    // MARK: - FIN CAS REELS
    
    func test_calcul_duree_assurance_sans_periode_de_chomage() throws {
        let nbTrimestreAcquis = 139
        let atEndOf           = 2020
        var lastKnownSituation    : RegimeGeneralSituation
        var dateOfRetirement      : Date
        var birthDate             : Date
        var extrapolationDuration : Int
        
        birthDate = date(year: 1964, month: 9, day: 22)
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : atEndOf,
                                                    nbTrimestreAcquis : nbTrimestreAcquis,
                                                    sam               : 37054.0)
        // Cessation d'activité 5 ans après la date du dernier relevé de situation
        extrapolationDuration = 5 // ans
        dateOfRetirement = extrapolationDuration.years.from(lastDayOf(year: atEndOf))!
        var duree = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                    .dureeAssurance(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : nil),
                                  "dureeAssurance failed")
        var theory = nbTrimestreAcquis + extrapolationDuration * 4 // 159
        XCTAssertEqual(theory, duree.plafonne)
        XCTAssertEqual(theory, duree.deplafonne)
        
        // Cessation d'activité 5 ans + 9 mois après la date du dernier relevé de situation
        dateOfRetirement = 3.quarters.from(dateOfRetirement)!
        duree = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                .dureeAssurance(
                                    birthDate                : birthDate,
                                    lastKnownSituation       : lastKnownSituation,
                                    dateOfRetirement         : dateOfRetirement,
                                    dateOfEndOfUnemployAlloc : nil),
                              "dureeAssurance failed")
        theory = nbTrimestreAcquis + extrapolationDuration * 4 + 3 // 162
        XCTAssertEqual(theory, duree.plafonne)
        XCTAssertEqual(theory, duree.deplafonne)
        
        // Cessation d'activité 20 ans après la date du dernier relevé de situation
        // la durée d'assurance ne peut dépasser la durée de référence soit 169 trimestres
        extrapolationDuration = 20 // ans
        dateOfRetirement = extrapolationDuration.years.from(lastDayOf(year: atEndOf))!
        duree = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                .dureeAssurance(
                                    birthDate                : birthDate,
                                    lastKnownSituation       : lastKnownSituation,
                                    dateOfRetirement         : dateOfRetirement,
                                    dateOfEndOfUnemployAlloc : nil),
                              "dureeAssurance failed")
        theory = 169 // durée de référence pour une personne née en 1964
        XCTAssertEqual(theory, duree.plafonne)
        XCTAssertNotEqual(duree.deplafonne, duree.plafonne)
    }
    
    func test_calcul_duree_assurance_avec_periode_de_chomage() throws {
        let birthDate         = date(year : 1964, month : 9, day : 22)
        let nbTrimestreAcquis = 139
        let atEndOf           = 2020
        var lastKnownSituation       : RegimeGeneralSituation
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date?
        
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : atEndOf,
                                                    nbTrimestreAcquis : nbTrimestreAcquis,
                                                    sam               : 0.0)
        // cas où la période de 20 trimestres (5 ans) de chomage non indemnisé (à +55 ans en fin d'indemnisation)
        // se prolonge au-delà de l'age min de départ à la retraite (62 ans)
        dateOfRetirement = 1.years.from(lastDayOf(year: lastKnownSituation.atEndOf))! // 31/12/2021
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement)! // 31/12/2024 + 5 ans = 31/12/2029 > 22/09/2026
        var duree = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                    .dureeAssurance(
                                        birthDate                : birthDate,
                                        lastKnownSituation       : lastKnownSituation,
                                        dateOfRetirement         : dateOfRetirement,
                                        dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc),
                                  "dureeAssurance failed")
        let case1 = nbTrimestreAcquis + (1 * 4) + (3 * 4) + 20 // 175
        let case2 = nbTrimestreAcquis + (1964 + 62 - atEndOf) * 4 - 2 // 161 à 62 ans pile
        let theory = min(case1, case2) // 161
        XCTAssertEqual(theory, duree.plafonne)
        
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : atEndOf,
                                                    nbTrimestreAcquis : 79,
                                                    sam               : 0.0)
        // cas où la période de 4 trimestres chomage (avec + de 80 trim acquis)
        // se termine avant l'age min de départ à la retraite (62 ans)
        dateOfRetirement = 1.years.before(lastDayOf(year: atEndOf))!
        dateOfEndOfUnemployAlloc = 2.years.from(lastDayOf(year: atEndOf))!
        duree = try XCTUnwrap(RegimeGeneralTest.regimeGeneral
                                .dureeAssurance(
                                    birthDate                : birthDate,
                                    lastKnownSituation       : lastKnownSituation,
                                    dateOfRetirement         : dateOfRetirement,
                                    dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc),
                              "dureeAssurance failed")
        XCTAssertEqual(79 + (2 + 1) * 4, duree.plafonne)
    }
    
    func test_calcul_nb_trimestre_de_surcote() {
        var dureeAssurance   : Int
        var dureeDeReference : Int
        var result: Result<Int, RegimeGeneral.ModelError>
        
        // pas de surcote
        dureeAssurance   = 135
        dureeDeReference = 140
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreSurcote(dureeAssurance   : dureeAssurance,
                                                                    dureeDeReference : dureeDeReference)
        switch result {
            case .success:
                XCTFail("fail")
                
            case .failure(let error):
                XCTAssertEqual(RegimeGeneral.ModelError.outOfBounds, error)
        }
        
        // surcote
        dureeAssurance   = 145
        dureeDeReference = 140
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreSurcote(dureeAssurance   : dureeAssurance,
                                                                    dureeDeReference : dureeDeReference)
        switch result {
            case .success(let nbTrimestreSurcote):
                XCTAssertEqual(dureeAssurance - dureeDeReference, nbTrimestreSurcote)
                
            case .failure:
                XCTFail("fail")
        }
    }
    
    func test_calcul_nb_Trimestre_de_Decote() {
        let now = now
        var dureeAssurance      : Int
        var dureeDeReference    : Int
        var birthDate           : Date
        var dateOfPensionLiquid : Date
        var result: Result<Int, RegimeGeneral.ModelError>
        
        // pas de decote
        birthDate           = now
        dateOfPensionLiquid = now
        dureeAssurance      = 145
        dureeDeReference    = 140
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreDecote(birthDate           : birthDate,
                                                                   dureeAssurance      : dureeAssurance,
                                                                   dureeDeReference    : dureeDeReference,
                                                                   dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
            case .success:
                // le test doit échouer car dureeAssurance > dureeDeReference
                XCTFail("fail")
                
            case .failure(let error):
                XCTAssertEqual(RegimeGeneral.ModelError.outOfBounds, error)
        }
        
        // decote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 65.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 145 // 5 trimestre manquant pour avoir tous les trimestres
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreDecote(birthDate           : birthDate,
                                                                   dureeAssurance      : dureeAssurance,
                                                                   dureeDeReference    : dureeDeReference,
                                                                   dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
            case .success(let nbTrimestreSurcote):
                XCTAssertEqual(dureeDeReference - dureeAssurance, nbTrimestreSurcote)
                
            case .failure:
                XCTFail("fail")
        }
        
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 65.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 150 // 10 trimestre manquant pour avoir tous les trimestres
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreDecote(birthDate           : birthDate,
                                                                   dureeAssurance      : dureeAssurance,
                                                                   dureeDeReference    : dureeDeReference,
                                                                   dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
            case .success(let nbTrimestreSurcote):
                XCTAssertEqual((67 - 65) * 4, nbTrimestreSurcote)
                
            case .failure:
                XCTFail("fail")
        }
        
        // decote plafonnée
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 57.years.from(birthDate)! // manquent 10 ans = 40 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 170 // 30 trimestre manquant pour avoir tous les trimestres
        result = RegimeGeneralTest.regimeGeneral.nbTrimestreDecote(birthDate           : birthDate,
                                                                   dureeAssurance      : dureeAssurance,
                                                                   dureeDeReference    : dureeDeReference,
                                                                   dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
            case .success(let nbTrimestreSurcote):
                XCTAssertEqual(20, nbTrimestreSurcote)
                
            case .failure:
                XCTFail("fail")
        }
    }
    
    func test_calcul_nb_Trimestre_Surcote_Ou_Decote() {
        var dureeAssurance      : Int
        var dureeDeReference    : Int
        var birthDate           : Date!
        var dateOfPensionLiquid : Date!
        var nbTrim : Int?
        
        // decote plafonnée
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 57.years.from(birthDate)! // manquent 10 ans = 40 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 170 // 30 trimestre manquant pour avoir tous les trimestres
        nbTrim = RegimeGeneralTest.regimeGeneral.nbTrimestreSurDecote(birthDate           : birthDate,
                                                                      dureeAssurance      : dureeAssurance,
                                                                      dureeDeReference    : dureeDeReference,
                                                                      dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(nbTrim)
        XCTAssertEqual(-20, nbTrim)
        
        // decote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 65.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 150 // 5 trimestre manquant pour avoir tous les trimestres
        nbTrim = RegimeGeneralTest.regimeGeneral.nbTrimestreSurDecote(birthDate           : birthDate,
                                                                      dureeAssurance      : dureeAssurance,
                                                                      dureeDeReference    : dureeDeReference,
                                                                      dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(nbTrim)
        XCTAssertEqual(-(67 - 65) * 4, nbTrim)
        
        // surcote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 60.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dureeAssurance   = 145
        dureeDeReference = 140
        nbTrim = RegimeGeneralTest.regimeGeneral.nbTrimestreSurDecote(birthDate           : birthDate,
                                                                      dureeAssurance      : dureeAssurance,
                                                                      dureeDeReference    : dureeDeReference,
                                                                      dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(nbTrim)
        XCTAssertEqual(dureeAssurance - dureeDeReference, nbTrim)
    }
    
    func test_coefficient_de_majoration_pour_Enfant() {
        XCTAssertEqual(0.0, RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 1))
        XCTAssertEqual(0.0, RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 2))
        XCTAssertEqual(10.0, RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 3))
        XCTAssertEqual(10.0, RegimeGeneralTest.regimeGeneral.coefficientMajorationEnfant(nbEnfant: 4))
    }
    
    func test_calcul_date_Taux_Plein() {
        var lastKnownSituation  : RegimeGeneralSituation
        var birthDate           : Date!
        var date                : Date?
        
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2020,
                                                    nbTrimestreAcquis : 139,
                                                    sam               : 0.0)
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : 1964,
                                         month    : 9,
                                         day      : 22)
        birthDate = Date.calendar.date(from: dateRefComp)!
        date = RegimeGeneralTest.regimeGeneral.dateAgeTauxPlein(
            birthDate          : birthDate,
            lastKnownSituation : lastKnownSituation)
        XCTAssertNotNil(date)
        XCTAssertEqual(2028, date!.year)
        XCTAssertEqual(6, date!.month)
        XCTAssertEqual(30, date!.day)
    }
    
    func test_date_Age_Minimum_Legal() {
        var birthDate           : Date!
        var date                : Date?
        
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : 1964,
                                         month    : 9,
                                         day      : 22)
        birthDate = Date.calendar.date(from: dateRefComp)!
        date = RegimeGeneralTest.regimeGeneral.dateAgeMinimumLegal(birthDate: birthDate)
        XCTAssertNotNil(date)
        XCTAssertEqual(1964 + 62, date!.year)
        XCTAssertEqual(9, date!.month)
        XCTAssertEqual(22, date!.day)
    }
    
    func test_date_Age_Taux_Plein_Legal() {
        var birthDate           : Date!
        var date                : Date?
        
        let dateRefComp = DateComponents(calendar : Date.calendar,
                                         year     : 1964,
                                         month    : 9,
                                         day      : 22)
        birthDate = Date.calendar.date(from: dateRefComp)!
        date = RegimeGeneralTest.regimeGeneral.dateTauxPleinLegal(birthDate: birthDate)
        XCTAssertNotNil(date)
        XCTAssertEqual(1964 + 67, date!.year)
        XCTAssertEqual(9, date!.month)
        XCTAssertEqual(22, date!.day)
    }
    
    func test_calcul_taux_de_pension() {
        var dureeAssurance      : Int
        var dureeDeReference    : Int
        var birthDate           : Date!
        var dateOfPensionLiquid : Date!
        var taux : Double?
        
        // decote plafonnée
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 57.years.from(birthDate)! // manquent 10 ans = 40 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 170 // 30 trimestre manquant pour avoir tous les trimestres
        taux = RegimeGeneralTest.regimeGeneral.tauxDePension(birthDate           : birthDate,
                                                             dureeAssurance      : dureeAssurance,
                                                             dureeDeReference    : dureeDeReference,
                                                             dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(taux)
        XCTAssertEqual(50.0 - 20.0 * 0.625, taux)
        
        // decote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 65.years.from(birthDate)! // manquent 2 ans = 8 trimestres manquant pour atteindre age du taux plein
        dureeAssurance      = 140
        dureeDeReference    = 150 // 5 trimestre manquant pour avoir tous les trimestres
        taux = RegimeGeneralTest.regimeGeneral.tauxDePension(birthDate           : birthDate,
                                                             dureeAssurance      : dureeAssurance,
                                                             dureeDeReference    : dureeDeReference,
                                                             dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(taux)
        XCTAssertEqual(50.0 - (67 - 65) * 4 * 0.625, taux)
        
        // surcote
        birthDate           = date(year: 1964, month: 9, day: 22) // age taux plein = 67 ans
        dateOfPensionLiquid = 60.years.from(birthDate)! // manquent 7 ans = 28 trimestres manquant pour atteindre age du taux plein
        dureeAssurance   = 145
        dureeDeReference = 140
        taux = RegimeGeneralTest.regimeGeneral.tauxDePension(birthDate           : birthDate,
                                                             dureeAssurance      : dureeAssurance,
                                                             dureeDeReference    : dureeDeReference,
                                                             dateOfPensionLiquid : dateOfPensionLiquid)
        XCTAssertNotNil(taux)
        XCTAssertEqual(50.0 * (1.0 + Double(dureeAssurance - dureeDeReference) * 1.25/100.0), taux)
    }
    
    func test_calcul_pension_sans_periode_de_chomage() {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var nbEnfant                 : Int
        var dateOfRetirement         : Date
        var dateOfPensionLiquid      : Date
        var theory                   : Double = 0
        let sam = 36698.0
        
        // cas de travail salarié jusqu'à la retraite à taux plein
        birthDate          = date(year: 1964, month: 9, day: 22)
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : sam)
        nbEnfant = 3
        dateOfRetirement = date(year: 2028, month: 7, day: 1) // date du taux plein
        dateOfPensionLiquid = dateOfRetirement
        
        if let (tauxDePension,
                majorationEnfant,
                dureeDeReference,
                dureeAssurancePlafonne,
                dureeAssuranceDeplafonne,
                pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfantNe               : nbEnfant,
                    during                   : nil) {
            
            XCTAssertEqual(10.0, majorationEnfant)
            XCTAssertEqual(169, dureeDeReference)
            XCTAssertEqual(169, dureeAssurancePlafonne)
            XCTAssertEqual(169, dureeAssuranceDeplafonne)
            XCTAssertEqual(50.0, tauxDePension)
            theory = lastKnownSituation.sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurancePlafonne.double() / dureeDeReference.double()
            print("** Cas de travail salarié jusqu'à la retraite à taux plein")
            print("**  - Pension annuelle  = \(theory)")
            print("**  - Pension mensuelle = \(theory / 12.0)")
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        if let (pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfantNe               : nbEnfant,
                    during                   : nil) {
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        
        // cas de travail salarié jusqu'à la retraite à 62 ans (décote)
        dateOfRetirement = (62.years + 10.days).from(birthDate)! // pousser au début du trimestre suivant
        dateOfPensionLiquid = dateOfRetirement
        if let (tauxDePension,
                majorationEnfant,
                dureeDeReference,
                dureeAssurancePlafonne,
                dureeAssuranceDeplafonne,
                pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfantNe               : nbEnfant,
                    during                   : nil) {
            
            XCTAssertEqual(10.0, majorationEnfant)
            XCTAssertEqual(169, dureeDeReference)
            let dureeAssTherory = 135 - 1 + (1964 + 62 - 2019) * 4 // 162
            XCTAssertEqual(dureeAssTherory, dureeAssurancePlafonne)
            XCTAssertEqual(dureeAssTherory, dureeAssuranceDeplafonne)
            let tauxTheory = 50.0 - Double((dureeDeReference - dureeAssuranceDeplafonne)) * 0.625 // 45.625
            XCTAssertEqual(tauxTheory, tauxDePension)
            theory = lastKnownSituation.sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurancePlafonne.double() / dureeDeReference.double()
            print("** Cas de travail salarié jusqu'à la retraite à 62 ans (décote)")
            print("**  - Pension annuelle  = \(theory)")
            print("**  - Pension mensuelle = \(theory / 12.0)")
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        if let (pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfantNe               : nbEnfant,
                    during                   : nil) {
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        
        // cas de travail salarié jusqu'à la retraite à 67 ans (surcote)
        dateOfRetirement = (67.years + 10.days).from(birthDate)!
        dateOfPensionLiquid = dateOfRetirement
        if let (tauxDePension,
                majorationEnfant,
                dureeDeReference,
                dureeAssurancePlafonne,
                dureeAssuranceDeplafonne,
                pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfantNe               : nbEnfant,
                    during                   : nil) {
            
            XCTAssertEqual(10.0, majorationEnfant)
            XCTAssertEqual(169, dureeDeReference)
            XCTAssertEqual(169, dureeAssurancePlafonne)
            let tauxTheory = 50.0 * (1.0 + Double(dureeAssuranceDeplafonne - dureeDeReference) * 1.25/100.0) // 66.25
            XCTAssertEqual(tauxTheory, tauxDePension)
            theory = lastKnownSituation.sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurancePlafonne.double() / dureeDeReference.double()
            print("** Cas de travail salarié jusqu'à la retraite à 67 ans (surcote)")
            print("**  - Pension annuelle  = \(theory)")
            print("**  - Pension mensuelle = \(theory / 12.0)")
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        if let (pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : nil,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfantNe               : nbEnfant,
                    during                   : nil) {
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        
        // cas de travail salarié jusqu'à fin 2021 puis rien jusqu'à liquidation à 62 ans
        dateOfRetirement = 62.years.from(birthDate)!
        dateOfPensionLiquid = 62.years.from(birthDate)!
        
    }
    
    func test_calcul_pension_avec_periode_de_chomage() {
        var birthDate                : Date
        var lastKnownSituation       : RegimeGeneralSituation
        var nbEnfant                 : Int
        var dateOfRetirement         : Date
        var dateOfEndOfUnemployAlloc : Date?
        var dateOfPensionLiquid      : Date
        var theory                   : Double = 0
        let sam = 36698.0
        
        // cas de travail salarié jusqu'à la retraite à taux plein
        birthDate          = date(year: 1964, month: 9, day: 22)
        lastKnownSituation = RegimeGeneralSituation(atEndOf           : 2019,
                                                    nbTrimestreAcquis : 135,
                                                    sam               : sam)
        nbEnfant = 3
        dateOfRetirement         = date(year : 2022, month : 1, day : 1) // fin d'activité salarié
        dateOfEndOfUnemployAlloc = 3.years.from(dateOfRetirement) // fin d'indemnisation chomage 3 ans plus tard
        dateOfPensionLiquid      = 62.years.from(birthDate)! // liquidation à 62 ans
        
        if let (tauxDePension,
                majorationEnfant,
                dureeDeReference,
                dureeAssurancePlafonne,
                dureeAssuranceDeplafonne,
                pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfantNe               : nbEnfant,
                    during                   : nil) {
            
            XCTAssertEqual(10.0, majorationEnfant)
            XCTAssertEqual(169, dureeDeReference)
            let case1 = 135 + (2 * 4) + (3 * 4) + 20 // 175
            let case2 = 135 - 2 + (1964 + 62 - 2019) * 4 // 161 à 62 ans
            let dureeAssTheory = min(case1, case2) // 161
            XCTAssertEqual(dureeAssTheory, dureeAssurancePlafonne)
            XCTAssertEqual(dureeAssTheory, dureeAssuranceDeplafonne)
            let tauxTheory = 50.0 - Double(dureeDeReference - dureeAssurancePlafonne) * 0.625
            XCTAssertEqual(tauxTheory, tauxDePension)
            theory = lastKnownSituation.sam * tauxDePension/100 * (1.0 + majorationEnfant/100) * dureeAssurancePlafonne.double() / dureeDeReference.double()
            print("** Cas de travail salarié jusqu'à la retraite à taux plein")
            print("**  - Pension annuelle  = \(theory)")
            print("**  - Pension mensuelle = \(theory / 12.0)")
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
        if let (pensionBrute,
                _) = RegimeGeneralTest.regimeGeneral.pension(
                    birthDate                : birthDate,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc,
                    dateOfPensionLiquid      : dateOfPensionLiquid,
                    lastKnownSituation       : lastKnownSituation,
                    nbEnfantNe               : nbEnfant,
                    during                   : nil) {
            XCTAssertEqual(theory, pensionBrute)
        } else {
            XCTFail("test_calcul_pension = nil")
        }
    }
} // swiftlint:disable:this file_length
