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
    
    public struct MajorationPourEnfant: Codable, Equatable {
        public var majorPourEnfantsNes   : Double // % [0, 100]
        public var nbEnafntNesMin        : Int
        public var majorParEnfantACharge : Double // % [0, 100]
        public var plafondMajoEnfantNe   : Double // €
    }
    
    public struct Model: JsonCodableToBundleP, VersionableP, Equatable {
        enum CodingKeys: CodingKey { // swiftlint:disable:this nesting
            case version, gridAvantAgeLegal, gridApresAgelegal, valeurDuPoint, ageMinimum, majorationPourEnfant
        }
        
        public var version                 : Version
        public var gridAvantAgeLegal              : [SliceAvantAgeLegal]
        public var gridApresAgelegal              : [SliceApresAgeLegal]
        public var valeurDuPoint                  : Double // 1.2714
        public var ageMinimum                     : Int    // 57
        public var majorationPourEnfant           : MajorationPourEnfant
        // dependencies to other Models
        var regimeGeneral                  : RegimeGeneral!
        var netRegimeAgircProviderP        : NetRegimeAgircProviderP!
        var pensionDevaluationRateProvider : PensionDevaluationRateProviderP!

        public static func == (lhs: RegimeAgirc.Model, rhs: RegimeAgirc.Model) -> Bool {
            return lhs.version == rhs.version &&
            lhs.gridAvantAgeLegal == rhs.gridAvantAgeLegal &&
            lhs.gridApresAgelegal == rhs.gridApresAgelegal &&
            lhs.valeurDuPoint == rhs.valeurDuPoint &&
            lhs.ageMinimum == rhs.ageMinimum &&
            lhs.majorationPourEnfant == rhs.majorationPourEnfant
        }
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
