//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import Foundation
import os
import AppFoundation

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeGeneral")

extension RegimeGeneral {
    /// Calcul la durée d'assurance qui sera obtenue à la date au plus tard entre:
    /// (a) la date de fin d'activité professionnelle, non suivie de période de chomage `dateOfRetirement`
    /// (b) la date de la fin d'indemnisation chômage après une période de travail `dateOfEndOfUnemployAlloc`
    ///
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de la fin d'indemnisation chômage après une période de travail
    /// - Returns: Durée d'assurance en nombre de trimestres
    ///    - deplafonne: peut être supérieur au nombre de trimestres de référence nécessaires pour obtenir le taux plein
    ///    - plafonne: valeur plafonnée au nombre de trimestres de référence nécessaires pour obtenir le taux plein
    /// - Warning: La durée d'assurance ne peut dépasser la durée de référence (le nb de trimestre pour obtenir le taux plein = F(année de naissance))
    /// - Note:
    ///   - [service-public](https://www.service-public.fr/particuliers/vosdroits/F31249)
    ///   - [la-retraite-en-clair](https://www.la-retraite-en-clair.fr/parcours-professionnel-regimes-retraite/periode-inactivite-retraite/chomage-retraite)
    func dureeAssurance(birthDate                : Date,
                        lastKnownSituation       : RegimeGeneralSituation,
                        dateOfRetirement         : Date,
                        dateOfEndOfUnemployAlloc : Date?) ->
    (deplafonne : Int,
     plafonne   : Int)? {
        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else {
            customLog.log(level: .default, "duree De Reference = nil")
            return nil
        }
        
        // date de la dernière situation connue
        let dateRef = lastDayOf(year: lastKnownSituation.atEndOf)
        
        var dateFinPeriodCotisationRetraite : Date
        if let dateFinAlloc = dateOfEndOfUnemployAlloc {
            // Période de travail suivi de période d'indemnisation chômage:
            // - Les périodes de chômage indemnisé sont considérées comme des trimestres d'assurance retraite au régime général de la Sécurité sociale dans la limite de 4 trimestres par an.
            // - Les périodes de chômage involontaire non indemnisé sont considérées comme des trimestres d'assurance retraite au régime général de la Sécurité sociale.
            //   - La 1re période de chômage non indemnisé, qu'elle soit continue ou non, est prise en compte dans la limite d'un an et demi (6 trimestres).
            //   - Chaque période ultérieure de chômage non indemnisé est prise en compte, dans la limite d’un an,
            //     à condition qu’elle succède sans interruption à une période de chômage indemnisé.
            //     - Cette deuxième limite est portée à 5 ans lorsque l’assuré justifie d’une durée de cotisation d’au moins 20 ans,
            //       est âgé d’au moins 55 ans à la date où il cesse de bénéficier du revenu de remplacement et ne relève pas à nouveau d’un régime obligatoire d’assurance vieillesse.
            
            // Calcul de l'âge à la date où il cesse de bénéficier du revenu de remplacement
            guard let age = Date.calendar.dateComponents([.year, .month, .day],
                                                         from: birthDate,
                                                         to  : dateFinAlloc).year else {
                customLog.log(level: .default, "âge à la date où il cesse de bénéficier du revenu de remplacement = nil")
                return nil
            }
            
            // Calcul du nombre de trimestre supplémetaires accordés au titre de la période de chômage non indemnisée
            guard let nbTrimSupplementaires = nbTrimAcquisApresPeriodNonIndemnise(nbTrimestreAcquis: lastKnownSituation.nbTrimestreAcquis,
                                                                                  ageAtEndOfUnemployementAlloc: age) else {
                customLog.log(level: .default, "nbTrimAcquisApresPeriodNonIndemnise = nil")
                return nil
            }
            // la période d'accumulation ne peut aller au-delà de l'age légal de départ en retraite (62 ans)
            dateFinPeriodCotisationRetraite = min(nbTrimSupplementaires.quarters.from(dateFinAlloc)!,
                                                  dateAgeMinimumLegal(birthDate: birthDate)!)
        } else {
            // période de travail non suivi de période d'indemnisation chômage
            dateFinPeriodCotisationRetraite = dateOfRetirement
        }
        
        var dureeDeplafonnee : Int
        if dateRef >= dateFinPeriodCotisationRetraite {
            // la date du dernier état est postérieure à la date de fin de cumul des trimestres, ils ne bougeront plus
            dureeDeplafonnee = lastKnownSituation.nbTrimestreAcquis
            return (deplafonne : dureeDeplafonnee,
                    plafonne   : min(dureeDeplafonnee, dureeDeReference))
            
        } else {
            // on a encore des trimestres à accumuler
            let duree = Date.calendar.dateComponents([.year, .month, .day],
                                                     from: dateRef,
                                                     to  : dateFinPeriodCotisationRetraite)
            let (q, _) = duree.month!.quotientAndRemainder(dividingBy: 3)
            //    Le nombre de trimestres est arrondi au chiffre inférieur
            let nbTrimestreFutur = zeroOrPositive((duree.year! * 4) + q)
            
            let dureeDeplafonnee = lastKnownSituation.nbTrimestreAcquis + nbTrimestreFutur
            return (deplafonne : dureeDeplafonnee,
                    plafonne   : min(dureeDeplafonnee, dureeDeReference))
        }
    }
}
