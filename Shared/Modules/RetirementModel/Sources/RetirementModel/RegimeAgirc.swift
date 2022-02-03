//
//  RegimeAgirc.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import AppFoundation
import Statistics
import SocioEconomyModel
import FiscalModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeAgirc")

// MARK: - Régime Complémentaire AGIRC-ARCCO

public struct RegimeAgircSituation: Codable {
    public var atEndOf     : Int
    public var nbPoints    : Int
    public var pointsParAn : Int
    
    internal init(atEndOf     : Int,
                  nbPoints    : Int,
                  pointsParAn : Int) {
        self.atEndOf     = atEndOf
        self.nbPoints    = nbPoints
        self.pointsParAn = pointsParAn
    }
    
    public init() {
        self.atEndOf     = CalendarCst.thisYear
        self.nbPoints    = 0
        self.pointsParAn = 0
    }
}

public final class RegimeAgirc: Codable {
    
    // MARK: - Nested types
    
    public struct SliceAvantAgeLegal: Codable, Hashable {
        public var ndTrimAvantAgeLegal : Int
        public var coef                : Double

        public init(ndTrimAvantAgeLegal: Int, coef: Double) {
            self.ndTrimAvantAgeLegal = ndTrimAvantAgeLegal
            self.coef = coef
        }
    }
    
    public struct SliceApresAgeLegal: Codable, Hashable {
        public var nbTrimManquant     : Int
        public var ndTrimPostAgeLegal : Int
        public var coef               : Double

        public init(nbTrimManquant     : Int,
                    ndTrimPostAgeLegal : Int,
                    coef               : Double) {
            self.nbTrimManquant = nbTrimManquant
            self.ndTrimPostAgeLegal = ndTrimPostAgeLegal
            self.coef = coef
        }
    }
    
    public struct MajorationPourEnfant: Codable {
        public var majorPourEnfantsNes   : Double // % [0, 100]
        public var nbEnafntNesMin        : Int
        public var majorParEnfantACharge : Double // % [0, 100]
        public var plafondMajoEnfantNe   : Double // €
    }
    
    public struct Model: JsonCodableToBundleP, VersionableP {
        enum CodingKeys: CodingKey { // swiftlint:disable:this nesting
            case version, gridAvantAgeLegal, gridApresAgelegal, valeurDuPoint, ageMinimum, majorationPourEnfant
        }
        
        public var version                 : Version
        var gridAvantAgeLegal              : [SliceAvantAgeLegal]
        var gridApresAgelegal              : [SliceApresAgeLegal]
        var valeurDuPoint                  : Double // 1.2714
        var ageMinimum                     : Int    // 57
        var majorationPourEnfant           : MajorationPourEnfant
        // dependencies to other Models
        var regimeGeneral                  : RegimeGeneral!
        var netRegimeAgircProviderP        : NetRegimeAgircProviderP!
        var pensionDevaluationRateProvider : PensionDevaluationRateProviderP!
    }
    
    // MARK: - Static Properties
    
    private static var simulationMode: SimulationModeEnum = .deterministic

    // MARK: - Static Methods

    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        RegimeAgirc.simulationMode = simulationMode
    }

    // MARK: - Properties
    
    public var model: Model

    // MARK: - Computed Properties

    public var gridAvantAgeLegal: [SliceAvantAgeLegal] {
        get { model.gridAvantAgeLegal }
        set { model.gridAvantAgeLegal = newValue }
    }

    public var gridApresAgelegal: [SliceApresAgeLegal] {
        get { model.gridApresAgelegal }
        set { model.gridApresAgelegal = newValue }
    }

    public var valeurDuPoint: Double {
        get { model.valeurDuPoint }
        set { model.valeurDuPoint = newValue }
    }
    
    public var ageMinimum: Int {
        get { model.ageMinimum }
        set { model.ageMinimum = newValue }
    }

    public var majorationPourEnfant: MajorationPourEnfant {
        get { model.majorationPourEnfant }
        set { model.majorationPourEnfant = newValue }
    }

    var devaluationRate: Double { // %
        model.pensionDevaluationRateProvider.pensionDevaluationRate(withMode: RegimeAgirc.simulationMode)
    }
    
    var yearlyRevaluationRate: Double { // %
        // on ne tient pas compte de l'inflation car les dépenses ne sont pas inflatées
        // donc les revenus non plus s'ils sont supposés progresser comme l'inflation
        // on ne tient donc compte que du delta par rapport à l'inflation
        -devaluationRate
    }
    
    // MARK: - Initializer
    
    init(model: Model) {
        self.model = model
    }
    
    // MARK: - Methods
    
    public func setPensionDevaluationRateProvider(_ provider : PensionDevaluationRateProviderP) {
        model.pensionDevaluationRateProvider = provider
    }
    
    public func setNetRegimeAgircProviderP(_ netRegimeAgircProviderP: NetRegimeAgircProviderP) {
        self.model.netRegimeAgircProviderP = netRegimeAgircProviderP
    }
    
    func setRegimeGeneral(_ regimeGeneral: RegimeGeneral) {
        model.regimeGeneral = regimeGeneral
    }
    
    /// Encode l'objet dans un fichier stocké dans le Bundle 
    func saveAsJSON(toFile file          : String,
                    toBundle bundle      : Bundle,
                    dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                    keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) {
        
        model.saveAsJSON(toFile               : file,
                           toBundle             : bundle,
                           dateEncodingStrategy : dateEncodingStrategy,
                           keyEncodingStrategy  :  keyEncodingStrategy)
    }
    
    /// Coefficient de réévaluation de la pension en prenant comme base 1.0
    ///  la valeur à la date de liquidation de la pension.
    /// - Parameters:
    ///   - year: année de calcul du coefficient
    ///   - dateOfPensionLiquid: date de liquidation de la pension
    /// - Returns: Coefficient multiplicateur
    /// - Note: Coefficient = coef de dévaluation par rapport à l'inflation
    ///
    ///   On ne tient pas compte de l'inflation car les dépenses ne sont pas inflatées
    ///   donc les revenus non plus s'ils sont supposés progresser comme l'inflation
    ///   on ne tient donc compte que du delta par rapport à l'inflation
    func revaluationCoef(during year         : Int,
                         dateOfPensionLiquid : Date) -> Double { // %
        pow(1.0 + yearlyRevaluationRate/100.0, Double(year - dateOfPensionLiquid.year))
    }
    
    /// Age minimum pour demander la liquidation de pension Agirc
    /// - Parameter birthDate: date de naissance
    /// - Returns: Age minimum pour demander la liquidation de pension Agirc
    func dateAgeMinimumAgirc(birthDate: Date) -> Date? {
        model.ageMinimum.years.from(birthDate)
    }
    
    /// Calcul du coefficient de minoration de la pension Agirc si la date de liquidation est avant l'age légal (62 ans)
    /// - Parameter ndTrimAvantAgeLegal: nb de trimestres entre la date de liquidation Agirc et la date de l'age légal
    /// - Returns: coefficient de minoration de la pension
    func coefDeMinorationAvantAgeLegal(ndTrimAvantAgeLegal: Int) -> Double? {
        model.gridAvantAgeLegal.last(\.coef, where: \.ndTrimAvantAgeLegal, <=, ndTrimAvantAgeLegal)
    }
    
    /// Calcul du coefficient de minoration de la pension Agirc si la date de liquidation est après l'age légal (62 ans)
    /// - Parameters:
    ///   - nbTrimManquantPourTauxPlein: nb de Trimestres Manquants avant l'âge légale du Taux Plein (67)
    ///   - nbTrimPostAgeLegalMin: nb de trimestres entre la date de l'age minimum légal (62) et la date de demande de liquidation Agirc
    /// - Returns: coefficient de minoration de la pension
    func coefDeMinorationApresAgeLegal(nbTrimManquantPourTauxPlein : Int,
                                       nbTrimPostAgeLegalMin       : Int) -> Double? {
        // coefficient de réduction basé sur le nb de trimestre manquants pour obtenir le taux plein
        guard let coef1 = model.gridApresAgelegal.last(\.coef, where: \.nbTrimManquant, <=, nbTrimManquantPourTauxPlein)  else {
            customLog.log(level: .default, "coefDeMinorationApresAgeLegal coef1 = nil")
            return nil
        }
        
        // coefficient basé sur l'age
        guard let coef2 = model.gridApresAgelegal.last(\.coef, where: \.ndTrimPostAgeLegal, >=, nbTrimPostAgeLegalMin)  else {
            customLog.log(level: .default, "coefDeMinorationApresAgeLegal coef2 = nil")
            return nil
        }
        
        // le coefficient applicable est déterminé par génération en fonction de l'âge atteint
        // ou de la durée d'assurance, en retenant la solution la plus avantageuse pour l'intéressé
        return max(coef1, coef2)
    }
    
    /// Projection du nombre de points Agirc sur la base du dernier relevé de points et de la prévision de carrière future
    /// - Parameters:
    ///   - lastAgircKnownSituation: dernier relevé de situation Agirc
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de la fin d'indemnisation chômage après une période de travail
    /// - Returns: nombre de points Agirc projeté à la liquidation de la pension
    func projectedNumberOfPoints(lastAgircKnownSituation  : RegimeAgircSituation,
                                 dateOfRetirement         : Date,
                                 dateOfEndOfUnemployAlloc : Date?) -> Int? {
        var nbPointsFuturActivite : Double
        var nbPointsFuturChomage  : Double
        
        let dateRef = lastDayOf(year: lastAgircKnownSituation.atEndOf)
        
        // nombre de points futurs dûs au titre de la future carrière de salarié
        if dateRef >= dateOfRetirement {
            // la date du dernier état est postérieure à la date de fin d'activité salarié
            nbPointsFuturActivite = 0.0
            
        } else {
            // période restant à cotiser à l'Agirc pendant la carrière de salarié
            let dureeRestant = Date.calendar.dateComponents([.year, .month, .day],
                                                            from: dateRef,
                                                            to  : dateOfRetirement)
            guard let anneesPleines = dureeRestant.year,
                  let moisPleins = dureeRestant.month else {
                customLog.log(level: .default, "anneesPleines OU moisPleins = nil")
                return nil
            }
            
            let nbAnneeRestant: Double = anneesPleines.double() + moisPleins.double() / 12
            nbPointsFuturActivite = lastAgircKnownSituation.pointsParAn.double() * nbAnneeRestant
        }
        
        // nombre de points futurs dûs au titre de la période de chomage indemnisé
        // https://www.previssima.fr/question-pratique/mes-periodes-de-chomage-comptent-elles-pour-ma-retraite-complementaire.html
        guard dateOfEndOfUnemployAlloc != nil else {
            // pas de période de chomage indemnisé donnant droit à des points supplémentaires
            return lastAgircKnownSituation.nbPoints + Int(nbPointsFuturActivite)
        }
        
        guard dateRef < dateOfEndOfUnemployAlloc! else {
            // la date du dernier état est postérieure à la date de fin d'indemnisation chomage, le nb de point ne bougera plus
            return lastAgircKnownSituation.nbPoints + Int(nbPointsFuturActivite)
        }
        // on a encore des trimestres à accumuler
        // période restant à cotiser à l'Agirc pendant la période de chomage indemnisée
        let dureeRestant = Date.calendar.dateComponents([.year, .month, .day],
                                                        from: dateRef > dateOfRetirement ? dateRef : dateOfRetirement,
                                                        to  : dateOfEndOfUnemployAlloc!)
        guard let anneesPleines = dureeRestant.year,
              let moisPleins = dureeRestant.month else {
            customLog.log(level: .default, "anneesPleines OU moisPleins = nil")
            return nil
        }
        let nbAnneeRestant: Double = anneesPleines.double() + moisPleins.double() / 12
        // le nb de point acqui par an au chomage semble être le même qu'en période d'activité
        // TODO: - pas tout à fait car il est basé sur le SJR qui peut être inférieur au salaire journalier réel: passer SJR en paramètre
        nbPointsFuturChomage = lastAgircKnownSituation.pointsParAn.double() * nbAnneeRestant
        
        return lastAgircKnownSituation.nbPoints + Int(nbPointsFuturActivite + nbPointsFuturChomage)
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
    func coefMinorationMajoration(birthDate                : Date, // swiftlint:disable:this function_parameter_count cyclomatic_complexity
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
    
    /// Calcul du coefficient de majoration pour enfants nés ou élevés
    /// - Parameter nbEnfantNe: nombre d'enfants nés ou élevés
    /// - Returns: coefficient de majoration [0, 1]
    /// - Note:
    ///   - [agirc-arrco.fr](https://lesexpertsretraite.agirc-arrco.fr/questions/1769054-retraite-complementaire-agirc-arrco-majorations-liees-enfants)
    ///   - [previssima.fr](https://www.previssima.fr/question-pratique/retraite-agirc-arrco-quelles-sont-les-majorations-pour-enfants.html)
    func coefMajorationPourEnfantNe(nbEnfantNe: Int) -> Double {
        switch nbEnfantNe {
            case 3...:
                return 1.0 + model.majorationPourEnfant.majorPourEnfantsNes / 100.0
            default:
                return 1.0
        }
    }
    
    /// Calcul de la mojoration de pension en € pour enfants nés ou élevés (plafonnée)
    /// - Parameters:
    ///   - pensionBrute: montant de la pension brute
    ///   - nbEnfantNe: nombre d'enfants nés ou élevés
    /// - Returns: mojoration de pension en €
    func majorationPourEnfantNe(pensionBrute : Double,
                                nbEnfantNe   : Int) -> Double {
        let coefMajoration = coefMajorationPourEnfantNe(nbEnfantNe: nbEnfantNe)
        let majoration = pensionBrute * (coefMajoration - 1.0)
        // plafonnement de la majoration
        return min(majoration, model.majorationPourEnfant.plafondMajoEnfantNe)
    }
    
    /// Calcul du coefficient de majoration pour enfant à charge
    /// - Parameter nbEnfantACharge: nb d'enfant de moins de 18 ans ou de 21 ans à charge ou de 25 faisant des études
    /// - Returns: coefficient de majoration [0, 1]
    /// - Note:
    ///   - [agirc-arrco.fr](https://lesexpertsretraite.agirc-arrco.fr/questions/1769054-retraite-complementaire-agirc-arrco-majorations-liees-enfants)
    ///   - [previssima.fr](https://www.previssima.fr/question-pratique/retraite-agirc-arrco-quelles-sont-les-majorations-pour-enfants.html)
    func coefMajorationPourEnfantACharge(nbEnfantACharge : Int) -> Double {
        switch nbEnfantACharge {
            case 1...:
                return 1.0 + Double(nbEnfantACharge) * model.majorationPourEnfant.majorParEnfantACharge / 100.0
            default:
                return 1.0
        }
    }
}
