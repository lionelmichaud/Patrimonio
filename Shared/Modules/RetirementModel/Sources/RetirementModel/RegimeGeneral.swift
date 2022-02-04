//
//  RegimeGeneral.swift
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

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.RegimeGeneral")

// MARK: - Régime Général

public struct RegimeGeneralSituation: Codable {
    public var atEndOf           : Int
    public var nbTrimestreAcquis : Int
    public var sam               : Double

    public init(atEndOf           : Int,
                nbTrimestreAcquis : Int,
                sam               : Double) {
        self.atEndOf           = atEndOf
        self.nbTrimestreAcquis = nbTrimestreAcquis
        self.sam               = sam
    }
    
    public init() {
        self.atEndOf           = CalendarCst.thisYear
        self.nbTrimestreAcquis = 0
        self.sam               = 0
    }
    
}

public final class RegimeGeneral: Codable {
    
    // MARK: - Nested types
    
    enum ModelError: String, CustomStringConvertible, Error {
        case impossibleToCompute
        case ilegalValue
        case outOfBounds
        
        var description: String {
            self.rawValue
        }
    }
    
    public struct SliceRegimeLegal: Codable, Hashable {
        public var birthYear   : Int
        /// nb de trimestre pour bénéficer du taux plein
        public var ndTrimestre : Int
        /// age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimum
        public var ageTauxPlein: Int

        public init(birthYear    : Int,
                    ndTrimestre  : Int,
                    ageTauxPlein : Int) {
            self.birthYear = birthYear
            self.ndTrimestre = ndTrimestre
            self.ageTauxPlein = ageTauxPlein
        }
    }
    
    public struct SliceUnemployement: Codable, Hashable {
        public var nbTrimestreAcquis  : Int
        public var nbTrimNonIndemnise : Int

        public init(nbTrimestreAcquis  : Int,
                    nbTrimNonIndemnise : Int) {
            self.nbTrimestreAcquis  = nbTrimestreAcquis
            self.nbTrimNonIndemnise = nbTrimNonIndemnise
        }
    }
    
    public struct Model: JsonCodableToBundleP, VersionableP {
        enum CodingKeys: CodingKey { // swiftlint:disable:this nesting
            case version, dureeDeReferenceGrid, nbTrimNonIndemniseGrid, ageMinimumLegal,
            nbOfYearForSAM, maxReversionRate, decoteParTrimestre, surcoteParTrimestre, maxNbTrimestreDecote,
            majorationTauxEnfant
        }
        
        public var version           : Version
        var dureeDeReferenceGrid     : [SliceRegimeLegal]
        var nbTrimNonIndemniseGrid   : [SliceUnemployement]
        var ageMinimumLegal          : Int    // 62
        let nbOfYearForSAM           : Int    // 25 pour le calcul du SAM
        var maxReversionRate         : Double // 50.0 // % du SAM [0, 100]
        var decoteParTrimestre       : Double // 0.625 // % par trimestre [0, 100]
        var surcoteParTrimestre      : Double // 1.25  // % par trimestre [0, 100]
        var maxNbTrimestreDecote     : Int    // 20 // plafond
        var majorationTauxEnfant     : Double // 10.0 // % [0, 100]
        var netRegimeGeneralProvider : NetRegimeGeneralProviderP!
        var socioEconomy             : SocioEconomyModelProviderP!
    }
    
    // MARK: - Static Properties
    
    private static var simulationMode: SimulationModeEnum = .deterministic
    // dependencies to other Models

    // En % [1, 100]
    var devaluationRate: Double {
        model.socioEconomy.pensionDevaluationRate(withMode: RegimeGeneral.simulationMode)
    }
    
    // En % [1, 100]
    var nbTrimAdditional: Double { // % [1, 100]
        model.socioEconomy.nbTrimTauxPlein(withMode: RegimeGeneral.simulationMode)
    }
    
    // En % [1, 100]
    var yearlyRevaluationRate: Double { // % [1, 100]
        // on ne tient pas compte de l'inflation car les dépenses ne sont pas inflatées
        // donc les revenus non plus s'ils sont supposés progresser comme l'inflation
        // on ne tient donc compte que du delta par rapport à l'inflation
        -devaluationRate
    }
    
    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        RegimeGeneral.simulationMode = simulationMode
    }

    public func setSocioEconomyModel(_ model: SocioEconomyModelProviderP) {
        self.model.socioEconomy = model
    }

    public func setNetRegimeGeneralProvider(_ provider: NetRegimeGeneralProviderP) {
        self.model.netRegimeGeneralProvider = provider
    }

    /// Coefficient de réévaluation de la pension en prenant comme base 1.0:
    /// la valeur à la date de liquidation de la pension.
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
    
    // MARK: - Properties
    
    /// dependency to model
    public var model: Model
    
    public var dureeDeReferenceGrid: [SliceRegimeLegal] {
        get { model.dureeDeReferenceGrid }
        set { model.dureeDeReferenceGrid = newValue }
    }

    public var nbTrimNonIndemniseGrid: [SliceUnemployement] {
        get { model.nbTrimNonIndemniseGrid }
        set { model.nbTrimNonIndemniseGrid = newValue }
    }

    public var ageMinimumLegal: Int {
        get { model.ageMinimumLegal }
        set { model.ageMinimumLegal = newValue }
    }

    public var maxReversionRate: Double {
        get { model.maxReversionRate }
        set { model.maxReversionRate = newValue }
    }

    public var decoteParTrimestre: Double {
        get { model.decoteParTrimestre }
        set { model.decoteParTrimestre = newValue }
    }

    public var surcoteParTrimestre: Double {
        get { model.surcoteParTrimestre }
        set { model.surcoteParTrimestre = newValue }
    }

    public var maxNbTrimestreDecote: Int {
        get { model.maxNbTrimestreDecote }
        set { model.maxNbTrimestreDecote = newValue }
    }

    public var majorationTauxEnfant: Double {
        get { model.majorationTauxEnfant }
        set { model.majorationTauxEnfant = newValue }
    }

    // MARK: - Initializer
    
    init(model: Model) {
        self.model = model
    }
    
    // MARK: - Methods

    /// Encode l'objet dans un fichier stocké dans le Bundle de contenant la définition de la classe aClass
    func saveAsJSON(toFile file          : String,
                    toBundle bundle      : Bundle,
                    dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                    keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) {

        model.saveAsJSON(toFile               : file,
                         toBundle             : bundle,
                         dateEncodingStrategy : dateEncodingStrategy,
                         keyEncodingStrategy  :  keyEncodingStrategy)
    }
    
    /// Calcul du taux de reversion en tenant compte d'une décote ou d'une surcote éventuelle
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - dureeAssurance: nombre de trimestres d'assurance obtenus
    ///   - dureeDeReference: nombre de trimestres de référence pour obtenir le taux plein
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension
    /// - Returns: taux de reversion en tenant compte d'une décote éventuelle en % [0%, 100%]
    /// - Note: [service-public](https://www.service-public.fr/particuliers/vosdroits/F21552)
    func tauxDePension(birthDate           : Date,
                       dureeAssurance      : Int,
                       dureeDeReference    : Int,
                       dateOfPensionLiquid : Date) -> Double? {
        let result = nbTrimestreDecote(birthDate           : birthDate,
                                       dureeAssurance      : dureeAssurance,
                                       dureeDeReference    : dureeDeReference,
                                       dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
            case .success(let nbTrimestreDecote):
                // décote
                return model.maxReversionRate - model.decoteParTrimestre * nbTrimestreDecote.double()
                
            case .failure(let error):
                switch error {
                    case .outOfBounds:
                        // surcote
                        let result = nbTrimestreSurcote(dureeAssurance   : dureeAssurance,
                                                        dureeDeReference : dureeDeReference)
                        switch result {
                            case .success(let nbTrimestreSurcote):
                                // TODO: - prendre aussi en compte le cas Salarié plus favorable
                                return model.maxReversionRate * (1.0 + model.surcoteParTrimestre * nbTrimestreSurcote.double() / 100.0)
                                
                            case .failure(let error):
                                customLog.log(level: .default, "nbTrimestreSurcote: \(error)")
                                return nil
                        }
                        
                    default:
                        customLog.log(level: .default, "nbTrimestreDecote: \(error)")
                        return nil
                }
        }
    }
    
    /// Calcul la décote (-) ou surcote (+) en nmbre de trimestre
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - dureeAssurance: nombre de trimestres d'assurance obtenus (déplafonné)
    ///   - dureeDeReference: nombre de trimestres de référence pour obtenir le taux plein
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension
    /// - Returns: décote (-) ou surcote (+) en nmbre de trimestre
    public func nbTrimestreSurDecote(birthDate           : Date,
                                     dureeAssurance      : Int,
                                     dureeDeReference    : Int,
                                     dateOfPensionLiquid : Date) -> Int? {
        let result = nbTrimestreDecote(birthDate           : birthDate,
                                       dureeAssurance      : dureeAssurance,
                                       dureeDeReference    : dureeDeReference,
                                       dateOfPensionLiquid : dateOfPensionLiquid)
        switch result {
            case .success(let nbTrimestreDecote):
                // il y a decote
                return -nbTrimestreDecote
                
            case .failure(let error):
                // il devrait y avoir surcote
                switch error {
                    case .outOfBounds:
                        let result = nbTrimestreSurcote(dureeAssurance   : dureeAssurance,
                                                        dureeDeReference : dureeDeReference)
                        switch result {
                            case .success(let nbTrimestreSurcote):
                                return nbTrimestreSurcote
                                
                            case .failure:
                                return nil
                        }
                        
                    default:
                        return nil
                }
        }
    }
    
    /// Calcul le nombre de trimestres supplémentaires obtenus, au-delà du minimum requis pour avoir une pension à taux plein
    /// - Parameters:
    ///   - dureeAssurance: nombre de trimestres d'assurance obtenus
    ///   - dureeDeReference: nombre de trimestres de référence pour obtenir le taux plein
    /// - Returns: nombre de trimestres de surcote obtenus
    /// - Note: [service-public](https://www.service-public.fr/particuliers/vosdroits/F19643)
    func nbTrimestreSurcote(dureeAssurance   : Int,
                            dureeDeReference : Int) -> Result<Int, ModelError> {
        /// le nombre de trimestres supplémentaires entre la date de votre départ en retraite et
        /// la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein
        guard dureeAssurance >= dureeDeReference else {
            return .failure(.outOfBounds)
        }
        
        let trimestreDeSurcote = dureeAssurance - dureeDeReference
        return .success(trimestreDeSurcote)
    }
    
    /// Calcul le nombre de trimestres manquants pour avoir une pension à taux plein
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - dureeAssurance: nb de trimestres cotisés
    ///   - dureeDeReference: nb de trimestres cotisés minimum pour avoir une pension à taux plein
    ///   - dateOfPensionLiquid: date de demande de liquidation de la pension de retraite
    /// - Returns: nombre de trimestres manquants pour avoir une pension à taux plein ou nil
    /// - Important: Pour déterminer le nombre de trimestres manquants, votre caisse de retraite compare :
    /// le nombre de trimestres manquants entre la date de votre départ en retraite et la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein,
    /// et le nombre de trimestres manquant entre la date de votre départ en retraite et la durée d'assurance retraite ouvrant droit au taux plein.
    /// Le nombre de trimestres est arrondi au chiffre supérieur. Le nombre de trimestres manquants retenu est le plus avantageux pour vous.
    /// Le nombre de trimestres est plafonné à 20
    /// - Note: [service-public](https://www.service-public.fr/particuliers/vosdroits/F19666)
    func nbTrimestreDecote(birthDate           : Date,
                           dureeAssurance      : Int,
                           dureeDeReference    : Int,
                           dateOfPensionLiquid : Date) -> Result<Int, ModelError> {
        guard dureeAssurance < dureeDeReference else {
            return .failure(.outOfBounds)
        }
        
        /// le nombre de trimestres manquants entre la date de votre départ en retraite et
        /// la date à laquelle vous atteignez l'âge permettant de bénéficier automatiquement du taux plein
        guard let dateDuTauxPlein = ageTauxPleinLegal(birthYear: birthDate.year)?.years.from(birthDate) else {
            customLog.log(level: .default, "date Du Taux Plein = nil")
            return .failure(.impossibleToCompute)
        }
        
        let duree = Date.calendar.dateComponents([.year, .month, .day],
                                                 from : dateOfPensionLiquid,
                                                 to   : dateDuTauxPlein)
        let (q1, r1) = duree.month!.quotientAndRemainder(dividingBy: 3)
        
        //    Le nombre de trimestres est arrondi au chiffre supérieur
        let trimestresManquantAgeTauxPlein = zeroOrPositive((duree.year! * 4) + (r1 > 0 ? q1 + 1 : q1))
        
        /// le nombre de trimestres manquant entre le nb de trimestre accumulés à la date de votre départ en retraite et
        /// la durée d'assurance retraite ouvrant droit au taux plein
        let trimestresManquantNbTrimestreTauxPlein = zeroOrPositive(dureeDeReference - dureeAssurance)
        
        // retenir le plus favorable des deux et limiter à 20 max
        return .success(min(trimestresManquantNbTrimestreTauxPlein,
                            trimestresManquantAgeTauxPlein,
                            model.maxNbTrimestreDecote))
    }
    
    /// Trouve  le nombre maximum de trimestre accumulable pendant une période de chômage non indemnisé
    /// suivant une période de de chômage indemnisé
    /// - Parameter nbTrimestreAcquis: nombre de trimestre cotisé au moment où débute la période de chômage non indemnisé
    /// - Parameter ageAtEndOfUnemployementAlloc: age à la date où il cesse de bénéficier du revenu de remplacement
    /// - Returns: nombre maximum de trimestre accumulable pendant une période de chômage non indemnisé
    func nbTrimAcquisApresPeriodNonIndemnise(nbTrimestreAcquis            : Int,
                                             ageAtEndOfUnemployementAlloc : Int) -> Int? {
        if ageAtEndOfUnemployementAlloc >= 55 {
            return model.nbTrimNonIndemniseGrid.last(\.nbTrimNonIndemnise, where: \.nbTrimestreAcquis, <=, nbTrimestreAcquis)
        } else {
            return model.nbTrimNonIndemniseGrid.last(\.nbTrimNonIndemnise, where: \.nbTrimestreAcquis, <=, 0)
        }
    }
    
    /// Trouve  la durée de référence pour obtenir une pension à taux plein
    /// - Parameter birthYear: Année de naissance
    /// - Returns: Durée de référence en nombre de trimestres pour obtenir une pension à taux plein ou nil
    func dureeDeReference(birthYear : Int) -> Int? {
        model.dureeDeReferenceGrid.last(\.ndTrimestre, where: \.birthYear, <=, birthYear)
    }
    
    /// Calcul le nb de trimestre manquant à la date au plus tard entre:
    /// (a) la date de fin d'activité professionnelle, non suivie de période de chomage (dateOfRetirement)
    /// (b) la date de la fin d'indemnisation chômage après une période de travail (dateOfEndOfUnemployAlloc)
    /// - Parameters:
    ///   - birthDate: Date de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    ///   - dateOfRetirement: date de cessation d'activité
    ///   - dateOfEndOfUnemployAlloc: date de la fin d'indemnisation chômage après une période de travail
    /// - Returns: nb de trimestre manquant à la date de fin d'activité professionnelle ou d'indemnisation, pour obtenir le taux plein
    /// - Note: [la-retraite-en-clair](https://www.la-retraite-en-clair.fr/parcours-professionnel-regimes-retraite/periode-inactivite-retraite/chomage-retraite)
    func nbTrimManquantPourTauxPlein(birthDate                : Date,
                                     lastKnownSituation       : RegimeGeneralSituation,
                                     dateOfRetirement         : Date,
                                     dateOfEndOfUnemployAlloc : Date?) -> Int? {
        dureeDeReference(birthYear: birthDate.year) - dureeAssurance(birthDate               : birthDate,
                                                                     lastKnownSituation      : lastKnownSituation,
                                                                     dateOfRetirement        : dateOfRetirement,
                                                                     dateOfEndOfUnemployAlloc: dateOfEndOfUnemployAlloc)?.deplafonne
    }
    
    /// Trouve l'age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimum
    /// - Parameter birthYear: Année de naissance
    /// - Returns: Age minimum pour bénéficer du taux plein sans avoir le nb de trimestres minimumou nil
    public func ageTauxPleinLegal(birthYear : Int) -> Int? {
        model.dureeDeReferenceGrid.last(\.ageTauxPlein, where: \.birthYear, <=, birthYear)
    }
    
    /// Calcule la date d'obtention du taux plein légal de retraite
    /// - Parameters:
    ///   - birthDate: date de naissance
    /// - Returns: date d'obtention du taux plein légal de retraite
    func dateTauxPleinLegal(birthDate: Date) -> Date? {
        guard let dateDuTauxPlein = ageTauxPleinLegal(birthYear: birthDate.year)?.years.from(birthDate) else {
            customLog.log(level: .default, "dateTauxPleinLegal: date Du Taux Plein = nil")
            return nil
        }
        return dateDuTauxPlein
    }
    
    func dateAgeMinimumLegal(birthDate: Date) -> Date? {
        model.ageMinimumLegal.years.from(birthDate)
    }
    
    /// Calcule la date d'obtention de tous les trimestres nécessaire pour obtenir le taux plein de retraite
    /// - Parameters:
    ///   - birthDate: date de naissance
    ///   - lastKnownSituation: dernière situation connue (année, nombre de trimestres de cotisation acquis)
    /// - Returns: date d'obtention de tous les trimestres nécessaire pour obtenir le taux plein de retraite
    /// - Warning: la calcul suppose que l'on continue à accumuler des trimestre en continu à partir de la date
    ///            du dernier relevé. C'est donc un meilleur cas.
    public func dateAgeTauxPlein(birthDate          : Date,
                                 lastKnownSituation : RegimeGeneralSituation) -> Date? {
        guard let dureeDeReference = dureeDeReference(birthYear: birthDate.year) else {
            customLog.log(level: .default, "duree De Reference = nil")
            return nil
        }
        let trimestreManquant = zeroOrPositive(dureeDeReference - lastKnownSituation.nbTrimestreAcquis)
        let dateRef = lastDayOf(year: lastKnownSituation.atEndOf)
        guard let dateTousTrimestre = (trimestreManquant * 3).months.from(dateRef) else {
            customLog.log(level: .default, "date Tous Trimestre = nil")
            return nil
        }
        return dateTousTrimestre
    }
    
    /// Rend la majoration de la pension pour enfants nés en %
    /// - Parameter nbEnfant: nombre d'enfants nés
    /// - Returns: coeffcient de majoration appliqué à la pension de retraite [0%, 10%]
    func coefficientMajorationEnfant(nbEnfant: Int) -> Double {
        switch nbEnfant {
            case 3...:
                return 10.0 // %
            default:
                return 0.0
        }
    }
}
