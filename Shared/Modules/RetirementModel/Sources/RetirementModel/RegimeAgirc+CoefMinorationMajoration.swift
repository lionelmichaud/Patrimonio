//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import Foundation
import os
import AppFoundation

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeAgirc")

extension RegimeAgirc {
    /// Calcul le coefficient de minoration ou de majoration de la pension complémentaire selon
    /// l'accord du 30 Octobre 2015.
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue pour le régime général
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de fin de perception des allocations chomage
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension
    ///   - year: année de calcul
    /// - Returns: Coefficient de minoration ou de majoration [0, 1]
    /// - Note:
    ///  - Age de départ à taux plein:
    ///     - Plusieurs situations se présentent:
    ///        - le salarié demande sa retraite complémentaire à la date à laquelle il bénéficie du taux plein dans le régime de base. Il subira une minoration de 10 % pendant 3 ans du montant de sa retraite complémentaire, et au maximum jusqu’à l’âge de 67 ans.
    ///        - le salarié demande sa retraite complémentaire 1 an après la date à laquelle il bénéficie du taux plein dans le régime de base. Il ne subira pas de coefficient de solidarité.
    ///        - le salarié demande sa retraite complémentaire 2 ans après la date à laquelle il bénéficie du taux plein dans le régime de base. Il bénéficie alors d’un bonus et sa pension de retraite complémentaire est alors majorée pendant 1 an de 10 %.
    ///        - s’il décale la liquidation de 3 ans, la majoration est de 20 %.
    ///        - s’il décale la liquidation de 4 ans, la majoration atteindra 30 %.
    ///  - Age de départ à taux minoré défintif:
    ///     - Vous pouvez aussi obtenir votre retraite complémentaire sans que les conditions ci-dessus soient remplies, sous réserve que vous ayez au minimum 57 ans.
    ///       Dans ce cas, le montant de votre retraite complémentaire sera diminué selon un coefficient de minoration, et cela de manière définitive.
    ///       La minoration dépend de l'âge que vous avez atteint au moment du départ à la retraite.
    ///       Si vous avez obtenu votre retraite de base à taux minoré et qu’il vous manque au minimum 20 trimestres pour bénéficier de la retraite de base à taux plein, la minoration appliquée est déterminée en fonction de votre âge ou du nombre de trimestres manquants.
    ///       La solution la plus favorable pour vous sera choisie.
    ///  - [www.agirc-arrco.fr](https://www.agirc-arrco.fr/particuliers/demander-retraite/conditions-pour-la-retraite/)
    ///  - [www.retraite.com](https://www.retraite.com/calcul-retraite/calcul-retraite-complementaire.html)
    func coefMinorationMajoration(birthDate                : Date, // swiftlint:disable:this cyclomatic_complexity
                                  lastKnownSituation       : RegimeGeneralSituation,
                                  dateOfRetirement         : Date,
                                  dateOfEndOfUnemployAlloc : Date?,
                                  dateOfPensionLiquid      : Date,
                                  during year              : Int) -> Double? {
        // nombre de trimestres accumulés en fin de carrière et de période indemnisée
        // au delà de celui nécessaire pour obtenir le taux plein an au régime général
        guard let nbTrimSupplementaire =
                -model.regimeGeneral.nbTrimManquantPourTauxPlein(
                    birthDate                : birthDate,
                    lastKnownSituation       : lastKnownSituation,
                    dateOfRetirement         : dateOfRetirement,
                    dateOfEndOfUnemployAlloc : dateOfEndOfUnemployAlloc) else {
            customLog.log(level: .default, "nbTrimSupplementaire = nil")
            return nil
        }
        //customLog.log(level: .info, "nb Trim Au-delà du Taux Plein = \(nbTrimAudelaDuTauxPlein, privacy: .public)")
        
        // age actuel et age du taux plein
        let age = year - birthDate.year
        guard let ageTauxPleinLegal =
                model.regimeGeneral.ageTauxPleinLegal(birthYear: birthDate.year) else {
            customLog.log(level: .default, "ageTauxPleinLegal: Age Du Taux Plein = nil")
            return nil
        }
        
        // délai écoulé depuis la date de liquidation de la pension
        let dateAtEndOfYear = lastDayOf(year: year)
        guard let delayAfterPensionLiquidation = Date.calendar.dateComponents([.year, .month, .day],
                                                                              from: dateOfPensionLiquid,
                                                                              to  : dateAtEndOfYear).year else {
            customLog.log(level: .default, "délai écoulé depuis la date de liqudation de la pension = nil")
            return nil
        }
        guard delayAfterPensionLiquidation >= 0 else {
            customLog.log(level: .default, "délai écoulé depuis la date de liqudation de la pension < 0")
            return nil
        }
        
        guard let dateAgeMinimumLegal = model.regimeGeneral.dateAgeMinimumLegal(birthDate: birthDate) else {
            customLog.log(level: .error,
                          "coefMinorationMajoration:dateAgeMinimumLegal = nil")
            fatalError("coefMinorationMajoration:dateAgeMinimumLegal = nil")
        }
        
        switch nbTrimSupplementaire {
            case ...(-1):
                // Liquidation de la pension AVANT l'obtention du taux plein
                //   => coefficient de minoration définitif
                return coefMinorationMajorationAvantTauxPlein(dateOfPensionLiquid,
                                                              dateAgeMinimumLegal,
                                                              nbTrimSupplementaire)
            case 0...:
                // Liquidation de la pension APRES l'obtention du taux plein
                //   Calculer le délai écoulé entre la date d'obtention du taux plein (ou la date de l'age minimum légal)
                //   et la date de liquidation de la pension
                
                let delaiDepuisAgeMinLegal = Date.calendar.dateComponents([.year, .month, .day],
                                                                          from: dateAgeMinimumLegal,
                                                                          to  : dateOfPensionLiquid)
                let nbTrimDepuisAgeMinLegal: Int = delaiDepuisAgeMinLegal.year! * 4 + delaiDepuisAgeMinLegal.month! / 3
                let nbTrimDepassantTauxPlein = min(nbTrimSupplementaire, nbTrimDepuisAgeMinLegal)
                switch nbTrimDepassantTauxPlein {
                    case 0...3:
                        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général
                        if age >= ageTauxPleinLegal {
                            // (2) on a dépassé l'âge d'obtention du taux plein légal
                            //     => taux plein
                            return 1.0
                        } else {
                            // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
                            //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
                            return delayAfterPensionLiquidation <= 3 ? 0.9 : 1.0
                        }
                        
                    case 4...7:
                        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général + 1 an
                        //     => taux plein
                        return 1.0
                        
                    case 8...11:
                        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général + 2 ans
                        if age >= ageTauxPleinLegal {
                            // (2) on a dépassé l'âge d'obtention du taux plein légal
                            //     => taux plein
                            return 1.0
                        } else {
                            // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
                            //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
                            return delayAfterPensionLiquidation <= 1 ? 1.1 : 1.0
                        }
                        
                    case 12...15:
                        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général + 3 ans
                        if age >= ageTauxPleinLegal {
                            // (2) on a dépassé l'âge d'obtention du taux plein légal
                            //     => taux plein
                            return 1.0
                        } else {
                            // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
                            //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
                            return delayAfterPensionLiquidation <= 1 ? 1.2 : 1.0
                        }
                        
                    case 16...19:
                        // (1) Liquidation dans l'année date d'obtention du taux plein au régime général + 4 ans
                        if age >= ageTauxPleinLegal {
                            // (2) on a dépassé l'âge d'obtention du taux plein légal
                            //     => taux plein
                            return 1.0
                        } else {
                            // (2) les 3 années suivant la date d'obtention du taux plein légal (et avant 67 ans)
                            //     => minoration de 10% pendant 3 ans s’applique au montant de votre retraite complémentaire
                            return delayAfterPensionLiquidation <= 1 ? 1.3 : 1.0
                        }
                        
                    case 20...:
                        // ce cas ne devrait pas se produire car (67-62) * 4 = 20
                        return 1.0
                        
                    default:
                        return nil
                }
                
            default:
                return nil
        }
    }
    
    fileprivate func coefMinorationMajorationAvantTauxPlein(_ dateOfPensionLiquid: Date,
                                                            _ dateAgeMinimumLegal: Date,
                                                            _ nbTrimAudelaDuTauxPlein: Int) -> Double? {
        // pension liquidable mais abattement définitif selon table
        // Délais restant à courir avant l'âge légal minimal de départ
        let delai = Date.calendar.dateComponents([.year, .month, .day],
                                                 from : dateOfPensionLiquid,
                                                 to   : dateAgeMinimumLegal)
        let (q1, r1) = delai.month!.quotientAndRemainder(dividingBy: 3)
        //    Le nombre de trimestres manquant est arrondi au chiffre supérieur
        let ndTrimAvantAgeLegal   = (delai.year! * 4) + (r1 > 0 ? q1 + 1 : q1)
        //    Le nombre de trimestres excédentaire est arrondi au chiffre inférieur
        let nbTrimPostAgeLegalMin = -(delai.year! * 4 + q1)
        
        let ecartTrimAgircLegal = (model.regimeGeneral.ageMinimumLegal - model.ageMinimum) * 4
        //let eacrtTrimLegalTauxPlein =
        
        switch ndTrimAvantAgeLegal {
            case ...0:
                // Liquidation de la pension AVANT l'obtention du taux plein
                // et APRES l'age l'age légal de liquidation de la pension du régime général
                // coefficient de minoration
                // (a) Nombre de trimestre manquant au moment de la liquidation de la pension pour pour obtenir le taux plein
                let nbTrimManquantPourTauxPlein = -nbTrimAudelaDuTauxPlein
                // (b) Nombre de trimestre manquant au moment de la liquidation de la pension pour atteindre l'age du taux plein légal
                //   nbTrimPostAgeLegalMin
                // (c) prendre le cas le plus favorable
                // coefficient de minoration
                guard let coef = coefDeMinorationApresAgeLegal(
                        nbTrimManquantPourTauxPlein : nbTrimManquantPourTauxPlein,
                        nbTrimPostAgeLegalMin       : nbTrimPostAgeLegalMin) else {
                    customLog.log(level: .default, "pension coef = nil")
                    return nil
                }
                return coef
                
            case 1...ecartTrimAgircLegal:
                // Liquidation de la pension AVANT l'obtention du taux plein
                // et AVANT l'age l'age légal de liquidation de la pension du régime général
                // et APRES l'age minimum de liquidation de la pension AGIRC
                // coefficient de minoration
                guard let coef = coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: ndTrimAvantAgeLegal) else {
                    customLog.log(level: .default, "pension coef = nil")
                    return nil
                }
                return coef
                
            case (ecartTrimAgircLegal+1)...:
                // Liquidation de la pension AVANT l'obtention du taux plein
                // et AVANT l'age l'age légal de liquidation de la pension du régime général
                // et AVANT l'age minimum de liquidation de la pension AGIRC
                // pas de pension AGIRC avant l'age minimum AGIRC
                return nil
                
            default:
                // on ne devrait jamais passer par là
                return nil
        }
    }
}
