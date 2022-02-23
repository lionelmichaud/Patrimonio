//
//  Adult.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//
import Foundation
import AppFoundation
import FiscalModel
import HumanLifeModel
import RetirementModel
import UnemployementModel
import ModelEnvironment
import DateBoundary

/// Revenu Brut, Net et Taxable
public struct BrutNetTaxable {
    public var brut    : Double
    public var net     : Double
    public var taxable : Double
    
    public init(brut: Double, net: Double, taxable: Double) {
        self.brut = brut
        self.net = net
        self.taxable = taxable
    }
}

/// Modèle d'un adulte
///
/// Usage:
///
///     let adult = Adult(from: decoder)
///     adult.initialize(using: model)
///
///     print(String(describing: adult)
///
///     adult.nextRandomProperties(using: model)
///     adult.nextRandomProperties(using: model)
///
///     adult.setRandomPropertiesDeterministicaly(using: model)
///
public final class Adult: Person {
    
    // MARK: - nested types
    
    private enum CodingKeys : String, CodingKey {
        case nb_Of_Child_Birth,
             fiscal_option,
             date_Of_Retirement,
             cause_Retirement,
             layoff_Compensation_Bonified,
             age_Of_Pension_Liquid,
             regime_General_Situation,
             age_Of_Agirc_Pension_Liquid,
             regime_Agirc_Situation,
             work_Income
    }
    
    // MARK: - Static Properties
    
    static var adultRelativesProvider: AdultRelativesProviderP!
    
    // MARK: - Static Methods
    
    public static func setAdultRelativesProvider(_ adultRelativesProvider: AdultRelativesProviderP) {
        self.adultRelativesProvider = adultRelativesProvider
    }
    
    // MARK: - Properties
    
    /// Nombre d'enfants nés
    @Published public var nbOfChildBirth: Int = 0
    
    /// SUCCESSION: option fiscale
    @Published public var fiscalOption : InheritanceFiscalOption = .fullUsufruct
    
    /// ACTIVITE: nature de revenu du travail
    @Published public var workIncome : WorkIncomeType?
    /// ACTIVITE: revenu du travail avant charges sociales, dépenses de mutuelle ou d'assurance perte d'emploi
    public var workBrutIncome    : Double {
        switch workIncome {
            case .salary(let brutSalary, _, _, _, _):
                return brutSalary
            case .turnOver(let BNC, _):
                return BNC
            case .none:
                return 0
        }
    }
    /// ACTIVITE: cause de cessation d'activité
    @Published public var causeOfRetirement: Unemployment.Cause = .demission
    /// ACTIVITE: date de cessation d'activité
    @Published public var dateOfRetirement : Date = Date.distantFuture
    public var dateOfRetirementComp        : DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: dateOfRetirement)
    } // computed
      /// ACTIVITE: âge de cessation d'activité
    public var ageOfRetirementComp         : DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: birthDateComponents, to: dateOfRetirementComp)
    } // computed

    /// CHOMAGE
    @Published public var layoffCompensationBonified : Double? // indemnité accordée par l'entreprise > légal (supra-légale)
    
    /// RETRAITE: date de demande de liquidation de pension régime général
    @Published public var ageOfPensionLiquidComp: DateComponents = DateComponents(calendar: Date.calendar, year: 62, month: 0, day: 1)
    /// RETRAITE: dernière situation connue au régime général
    @Published public var lastKnownPensionSituation = RegimeGeneralSituation()
    
    /// RETRAITE: date de demande de liquidation de pension complémentaire
    @Published public var ageOfAgircPensionLiquidComp: DateComponents = DateComponents(calendar: Date.calendar, year: 62, month: 0, day: 1)
    /// RETRAITE: dernière situation connue au régime complémentaire
    @Published public var lastKnownAgircPensionSituation = RegimeAgircSituation()
    
    /// DEPENDANCE: nombre d'années de dépendance
    @Published public var nbOfYearOfDependency : Int = 0
    /// DEPENDANCE: âge à l'entrée en dépendance
    public var ageOfDependency                 : Int {
        return ageOfDeath - nbOfYearOfDependency
    } // computed
    /// DEPENDANCE: année à l'entrée en dépendance
    public var yearOfDependency                : Int {
        return yearOfDeath - nbOfYearOfDependency
    } // computed
    public override var description: String {
        return super.description +
            """
        - Nombre d'années de dépendance: \(nbOfYearOfDependency)
        - Cessation d'activité - age :  \(ageOfRetirementComp)
        - Cessation d'activité - date: \(mediumDateFormatter.string(from: dateOfRetirement))
        - AGIRC pension liquidation - age :  \(ageOfAgircPensionLiquidComp)
        - AGIRC pension liquidation - date: \(dateOfAgircPensionLiquid.stringMediumDate)
        - Pension liquidation - age :  \(ageOfPensionLiquidComp)
        - Pension liquidation - date: \(dateOfPensionLiquid.stringMediumDate)
        - Nombre d'enfants: \(nbOfChildBirth)
        - Option fiscale à la succession: \(String(describing: fiscalOption))
        - Revenu:\(workIncome?.description.withPrefixedSplittedLines("  ") ?? "aucun")\n
        """
    }
    
    // MARK: - initialization
    
    /// Initialiser à partir d'un fichier JSON
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container =
            try decoder.container(keyedBy: CodingKeys.self)
        nbOfChildBirth =
            try container.decode(Int.self,
                                 forKey : .nb_Of_Child_Birth)
        fiscalOption =
            try container.decode(InheritanceFiscalOption.self,
                                 forKey : .fiscal_option)
        dateOfRetirement =
            try container.decode(Date.self,
                                 forKey: .date_Of_Retirement)
        causeOfRetirement =
            try container.decode(Unemployment.Cause.self,
                                 forKey: .cause_Retirement)
        layoffCompensationBonified =
            try container.decode(Double?.self,
                                 forKey: .layoff_Compensation_Bonified)
        ageOfPensionLiquidComp =
            try container.decode(DateComponents.self,
                                 forKey: .age_Of_Pension_Liquid)
        lastKnownPensionSituation =
            try container.decode(RegimeGeneralSituation.self,
                                 forKey: .regime_General_Situation)
        ageOfAgircPensionLiquidComp =
            try container.decode(DateComponents.self, forKey: .age_Of_Agirc_Pension_Liquid)
        lastKnownAgircPensionSituation =
            try container.decode(RegimeAgircSituation.self,
                                 forKey: .regime_Agirc_Situation)
        // initialiser avec la valeur moyenne déterministe
        workIncome =
            try container.decode(WorkIncomeType.self,
                                 forKey: .work_Income)
        
        try super.init(from: decoder)
        
        // pas de dépendance avant l'âge de 65 ans
        nbOfYearOfDependency = zeroOrPositive(ageOfDeath - 65)
    }
    
    public override init() {
        super.init()
    }
    
    // MARK: - methods
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nbOfChildBirth, forKey: .nb_Of_Child_Birth)
        try container.encode(fiscalOption, forKey: .fiscal_option)
        try container.encode(dateOfRetirement, forKey: .date_Of_Retirement)
        try container.encode(causeOfRetirement, forKey: .cause_Retirement)
        try container.encode(layoffCompensationBonified, forKey: .layoff_Compensation_Bonified)
        try container.encode(ageOfPensionLiquidComp, forKey: .age_Of_Pension_Liquid)
        try container.encode(lastKnownPensionSituation, forKey: .regime_General_Situation)
        try container.encode(ageOfAgircPensionLiquidComp, forKey: .age_Of_Agirc_Pension_Liquid)
        try container.encode(lastKnownAgircPensionSituation, forKey: .regime_Agirc_Situation)
        //        try container.encode(nbOfYearOfDependency, forKey: .nb_Of_Year_Of_Dependency)
        try container.encode(workIncome, forKey: .work_Income)
    }
    
    /// Initialise les propriétés qui ne peuvent pas l'être à la création
    /// quand le modèle n'est pas encore créé
    /// - Parameter model: modèle à utiliser
    public override func initialize(using model: Model) {
        //super.initialize(using: model)
        
        // initialiser le nombre d'années de dépendence
        setRandomPropertiesDeterministicaly(using: model)
    }
    
    /// Année ou a lieu l'événement recherché
    /// - Parameter event: événement recherché
    /// - Returns: Année ou a lieu l'événement recherché, nil si l'événement n'existe pas
    public override func yearOf(event: LifeEvent) -> Int? {
        switch event {
            case .debutEtude:
                return nil
                
            case .independance:
                return nil
                
            case .dependence:
                return yearOfDependency
                
            case .deces:
                return super.yearOf(event: event)
                
            case .cessationActivite:
                return dateOfRetirement.year
                
            case .liquidationPension:
                return dateOfPensionLiquid.year
            // TODO: ajouter la liquidation de la pension complémentaire
            // TODO: ajouter le licenciement
            // TODO: ajouter la fin des indemnités chomage
        }
    }

    /// Revenu net de feuille de paye, net de charges sociales et mutuelle obligatore
    public final func workNetIncome(using model: Model) -> Double {
        switch workIncome {
            case .salary(_, _, let netSalary, _, _):
                return netSalary
            case .turnOver(let BNC, _):
                return model.fiscalModel.turnoverTaxes.net(BNC)
            case .none:
                return 0
        }
    }

    /// Revenu net de feuille de paye et de mutuelle facultative ou d'assurance perte d'emploi
    public final func workLivingIncome(using model: Model) -> Double {
        switch workIncome {
            case .salary(_, _, let netSalary, _, let charge):
                return netSalary - charge
            case .turnOver(let BNC, let charge):
                return model.fiscalModel.turnoverTaxes.net(BNC) - charge
            case .none:
                return 0
        }
    }

    /// Revenu taxable à l'IRPP
    public final func workTaxableIncome(using model: Model) -> Double {
        switch workIncome {
            case .none:
                return 0
            default:
                return model.fiscalModel.incomeTaxes.taxableIncome(from: workIncome!)
        }
    }

    /// Définir le nombre d'enfants nés
    public final func gaveBirthTo(children : Int) {
        nbOfChildBirth = children
    }

    /// Nombre d'enfants fiscalement à charge
    public final func nbOfFiscalChildren(during year: Int) -> Int {
        Adult.adultRelativesProvider.nbOfFiscalChildren(during: year)
    }

    /// Nombre d'enfants nés
    public final func nbOfBornChildren() -> Int {
        // TODO: - à remplacer par un accès directe à self.nbOfChildBirth
        Adult.adultRelativesProvider.nbOfBornChildren
    }

    /// Définir l'âge de liquidation de la pension de retraite du régime général
    public final func setAgeOfPensionLiquidComp(year: Int, month: Int = 0, day: Int = 0) {
        ageOfPensionLiquidComp = DateComponents(calendar: Date.calendar, year: year, month: month, day: day)
    }

    /// Définir l'âge de liquidation de la pension de retraite du régime complémentaire
    public final func setAgeOfAgircPensionLiquidComp(year: Int, month: Int = 0, day: Int = 0) {
        ageOfAgircPensionLiquidComp = DateComponents(calendar: Date.calendar, year: year, month: month, day: day)
    }
    
    /// true si est vivant à la fin de l'année et encore en activité pendant une partie de l'année
    /// - Parameter year: année
    public final func isActive(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (year <= dateOfRetirement.year)
    }
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de cessation d'activité
    /// - Parameter year: année
    public final func isRetired(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfRetirement.year <= year)
    }
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime complémentaire
    /// - Parameter year: première année incluant des revenus
    public final func isDependent(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (yearOfDependency <= year)
    }
    
    /// Revenu net de charges pour vivre et revenu taxable à l'IRPP
    /// - Parameter year: année
    public final func workIncome(during year : Int,
                                 using model : Model)
    -> (net: Double, taxableIrpp: Double) {
        guard isActive(during: year) else {
            return (0, 0)
        }
        let nbWeeks = (dateOfRetirementComp.year == year ? dateOfRetirement.weekOfYear.double() : 52)
        return (net         : workLivingIncome(using: model)  * nbWeeks / 52,
                taxableIrpp : workTaxableIncome(using: model) * nbWeeks / 52)
    }
    
    /// Réinitialiser les prioriétés variables des membres de manière aléatoires
    public override final func nextRandomProperties(using model: Model) {
        super.nextRandomProperties(using: model)
        
        // générer une nouvelle valeure aléatoire
        // réinitialiser la durée de dépendance
        nbOfYearOfDependency = Int(model.humanLife.model!.nbOfYearsOfdependency.next())
        
        // pas de dépendance avant l'âge de 65 ans
        nbOfYearOfDependency = min(nbOfYearOfDependency, zeroOrPositive(ageOfDeath - 65))
    }
    
    /// Réinitialiser les prioriétés variables des membres de manière déterministe
    public override final func setRandomPropertiesDeterministicaly(using model: Model) {
        // initialiser l'age de décès
        super.setRandomPropertiesDeterministicaly(using: model)
        
        // initialiser le nombre d'années de dépendence
        // initialiser avec la valeur moyenne déterministe
        let modelValue = Int(model.humanLifeModel.nbOfYearsOfdependency.value(withMode: .deterministic))
        nbOfYearOfDependency =
            min(modelValue, zeroOrPositive(self.ageOfDeath - 65)) // pas de dépendance avant l'âge de 65 ans
        
        // vérifier la cohérence entre les âges de liquidation de pension du fichier person.json et
        // avec les âges au plus tôt du fichier RetirementModelConfig.json
        // Modifier les premières au besoin
        let ageMinimumLegal = model.retirementModel.regimeGeneral.ageMinimumLegal
        var ageLiquidationPension = max(ageOfPensionLiquidComp.year!, ageMinimumLegal)
        ageOfPensionLiquidComp = DateComponents(calendar: Date.calendar,
                                                year: ageLiquidationPension, month: 0, day: 1)
        
        let ageMinimumAGIRC = model.retirementModel.regimeAgirc.ageMinimum
        ageLiquidationPension = max(ageOfAgircPensionLiquidComp.year!, ageMinimumAGIRC)
        ageOfAgircPensionLiquidComp = DateComponents(calendar: Date.calendar,
                                                     year: ageLiquidationPension, month: 0, day: 1)
    }
    
    /// RETRAITE: pension évaluée l'année de la liquidation de la pension (non révaluée)
    public final func pension(using model: Model) -> BrutNetTaxable { // computed
        let pensionGeneral = pensionRegimeGeneral(using: model)
        let pensionAgirc   = pensionRegimeAgirc(using: model)
        let brut           = pensionGeneral.brut + pensionAgirc.brut
        let net            = pensionGeneral.net  + pensionAgirc.net
        let taxable        = try! model.fiscalModel.pensionTaxes.taxable(brut: brut, net:net)
        return BrutNetTaxable(brut: brut, net: net, taxable: taxable)
    }
}
