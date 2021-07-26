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

struct BrutNetTaxable {
    var brut    : Double
    var net     : Double
    var taxable : Double
}

final class Adult: Person {
    
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
    
    static var adultRelativesProvider: AdultRelativesProvider!
    
    // MARK: - Static Methods
    
    static func setAdultRelativesProvider(_ adultRelativesProvider: AdultRelativesProvider) {
        self.adultRelativesProvider = adultRelativesProvider
    }
    
    // MARK: - Properties
    
    // nombre d'enfants
    @Published var nbOfChildBirth: Int = 0
    
    /// SUCCESSION: option fiscale
    @Published var fiscalOption : InheritanceFiscalOption = .fullUsufruct

    /// ACTIVITE: revenus du travail
    @Published var workIncome : WorkIncomeType?
    var workBrutIncome    : Double { // avant charges sociales, dépenses de mutuelle ou d'assurance perte d'emploi
        switch workIncome {
            case .salary(let brutSalary, _, _, _, _):
                return brutSalary
            case .turnOver(let BNC, _):
                return BNC
            case .none:
                return 0
        }
    }
    var workNetIncome     : Double { // net de feuille de paye, net de charges sociales et mutuelle obligatore
        switch workIncome {
            case .salary(_, _, let netSalary, _, _):
                return netSalary
            case .turnOver(let BNC, _):
                return Fiscal.model.turnoverTaxes.net(BNC)
            case .none:
                return 0
        }
    }
    var workLivingIncome  : Double { // net de feuille de paye et de mutuelle facultative ou d'assurance perte d'emploi
        switch workIncome {
            case .salary(_, _, let netSalary, _, let charge):
                return netSalary - charge
            case .turnOver(let BNC, let charge):
                return Fiscal.model.turnoverTaxes.net(BNC) - charge
            case .none:
                return 0
        }
    }
    var workTaxableIncome : Double { // taxable à l'IRPP
        switch workIncome {
            case .none:
                return 0
            default:
                return Fiscal.model.incomeTaxes.taxableIncome(from: workIncome!)
        }
    }
    
    /// ACTIVITE: date et cause de cessation d'activité
    @Published var causeOfRetirement: Unemployment.Cause = .demission
    @Published var dateOfRetirement : Date = Date.distantFuture
    var dateOfRetirementComp        : DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: dateOfRetirement)
    } // computed
    var ageOfRetirementComp         : DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day], from: birthDateComponents, to: dateOfRetirementComp)
    } // computed
    var displayDateOfRetirement     : String { // computed
        mediumDateFormatter.string(from: dateOfRetirement)
    } // computed
    
    /// CHOMAGE
    @Published var layoffCompensationBonified : Double? // indemnité accordée par l'entreprise > légal (supra-légale)
    
    /// RETRAITE: date de demande de liquidation de pension régime général
    @Published var ageOfPensionLiquidComp: DateComponents = DateComponents(calendar: Date.calendar, year: 62, month: 0, day: 1)
    @Published var lastKnownPensionSituation = RegimeGeneralSituation()
    
    /// RETRAITE: date de demande de liquidation de pension complémentaire
    @Published var ageOfAgircPensionLiquidComp: DateComponents = DateComponents(calendar: Date.calendar, year: 62, month: 0, day: 1)
    @Published var lastKnownAgircPensionSituation = RegimeAgircSituation()
    
    /// DEPENDANCE
    @Published var nbOfYearOfDependency : Int = 0
    var ageOfDependency                 : Int {
        return ageOfDeath - nbOfYearOfDependency
    } // computed
    var yearOfDependency                : Int {
        return yearOfDeath - nbOfYearOfDependency
    } // computed
    override var description: String {
        return super.description +
        """
        - nombre d'années de dépendance: \(nbOfYearOfDependency)
        - age of retirement:  \(ageOfRetirementComp)
        - date of retirement: \(dateOfRetirement.stringMediumDate)
        - age of AGIRC pension liquidation:  \(ageOfAgircPensionLiquidComp)
        - date of AGIRC pension liquidation: \(dateOfAgircPensionLiquid.stringMediumDate)
        - age of pension liquidation:  \(ageOfPensionLiquidComp)
        - date of pension liquidation: \(dateOfPensionLiquid.stringMediumDate)
        - number of children: \(nbOfChildBirth)
        - taxable income: \(workTaxableIncome.€String)
        - Revenu:\(workIncome?.description.withPrefixedSplittedLines("  ") ?? "aucun")
          - Imposable: \(workLivingIncome.€String) (après abattement)\n
        """
    }
    
    // MARK: - initialization
    
    // reads from JSON
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
    
    override init(sexe       : Sexe,
                  givenName  : String,
                  familyName : String,
                  birthDate  : Date,
                  ageOfDeath : Int = CalendarCst.forever) {
        super.init(sexe: sexe, givenName: givenName, familyName: familyName, birthDate: birthDate, ageOfDeath: ageOfDeath)
    }
    
    // MARK: - methods
    
    override func encode(to encoder: Encoder) throws {
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
    override func initialize(using model: Model) {
        //super.initialize(using: model)
        
        // initialiser le nombre d'années de dépendence
        setRandomPropertiesDeterministicaly(using: model)
    }
    
    /// Année ou a lieu l'événement recherché
    /// - Parameter event: événement recherché
    /// - Returns: Année ou a lieu l'événement recherché, nil si l'événement n'existe pas
    override func yearOf(event: LifeEvent) -> Int? {
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
    
    func gaveBirthTo(children : Int) {
        if sexe == .female {nbOfChildBirth = children}
    }
    func addChild() {
        if sexe == .female {nbOfChildBirth += 1}
    }
    func removeChild() {
        if sexe == .female {nbOfChildBirth -= 1}
    }
    func nbOfFiscalChildren(during year: Int) -> Int {
        Adult.adultRelativesProvider.nbOfFiscalChildren(during: year)
    }
    func nbOfChildren() -> Int {
        Adult.adultRelativesProvider.nbOfChildren
    }
    func setAgeOfPensionLiquidComp(year: Int, month: Int = 0, day: Int = 0) {
        ageOfPensionLiquidComp = DateComponents(calendar: Date.calendar, year: year, month: month, day: day)
    }
    func setAgeOfAgircPensionLiquidComp(year: Int, month: Int = 0, day: Int = 0) {
        ageOfAgircPensionLiquidComp = DateComponents(calendar: Date.calendar, year: year, month: month, day: day)
    }
    
    /// true si est vivant à la fin de l'année et encore en activité pendant une partie de l'année
    /// - Parameter year: année
    func isActive(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (year <= dateOfRetirement.year)
    }
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de cessation d'activité
    /// - Parameter year: année
    func isRetired(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (dateOfRetirement.year <= year)
    }
    
    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de liquidation de la pension du régime complémentaire
    /// - Parameter year: première année incluant des revenus
    func isDependent(during year: Int) -> Bool {
        isAlive(atEndOf: year) && (yearOfDependency <= year)
    }
    
    /// Revenu net de charges pour vivre et revenu taxable à l'IRPP
    /// - Parameter year: année
    func workIncome(during year: Int)
    -> (net: Double, taxableIrpp: Double) {
        guard isActive(during: year) else {
            return (0, 0)
        }
        let nbWeeks = (dateOfRetirementComp.year == year ? dateOfRetirement.weekOfYear.double() : 52)
        return (net         : workLivingIncome  * nbWeeks / 52,
                taxableIrpp : workTaxableIncome * nbWeeks / 52)
    }
    
    /// Réinitialiser les prioriétés variables des membres de manière aléatoires
    override func nextRandomProperties(using model: Model) {
        super.nextRandomProperties(using: model)
        
        // générer une nouvelle valeure aléatoire
        // réinitialiser la durée de dépendance
        nbOfYearOfDependency = Int(model.humanLife.model!.nbOfYearsOfdependency.next())
        
        // pas de dépendance avant l'âge de 65 ans
        nbOfYearOfDependency = min(nbOfYearOfDependency, zeroOrPositive(ageOfDeath - 65))
    }
    
    /// Réinitialiser les prioriétés variables des membres de manière déterministe
    override func setRandomPropertiesDeterministicaly(using model: Model) {
        super.setRandomPropertiesDeterministicaly(using: model)
        
        // initialiser le nombre d'années de dépendence
        // initialiser avec la valeur moyenne déterministe
        let modelValue = Int(model.humanLifeModel.nbOfYearsOfdependency.value(withMode: .deterministic))
        nbOfYearOfDependency =
            min(modelValue, zeroOrPositive(self.ageOfDeath - 65)) // pas de dépendance avant l'âge de 65 ans
    }
    
    /// RETRAITE: pension évaluée l'année de la liquidation de la pension (non révaluée)
    func pension(using model: Model) -> BrutNetTaxable { // computed
        let pensionGeneral = pensionRegimeGeneral(using: model)
        let pensionAgirc   = pensionRegimeAgirc(using: model)
        let brut           = pensionGeneral.brut + pensionAgirc.brut
        let net            = pensionGeneral.net  + pensionAgirc.net
        let taxable        = try! Fiscal.model.pensionTaxes.taxable(brut: brut, net:net)
        return BrutNetTaxable(brut: brut, net: net, taxable: taxable)
    }
}
