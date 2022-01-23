//
//  ModelDeterministicViewModel.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 01/08/2021.
//

import Foundation
import ModelEnvironment
import RetirementModel
import FamilyModel

// MARK: - Deterministic View Model

class DeterministicViewModel: ObservableObject {
    
    // MARK: - Properties

    @Published var isModified : Bool
    // model: HumanLife
    @Published var menLifeExpectation    : Int
    @Published var womenLifeExpectation  : Int
    @Published var nbOfYearsOfdependency : Int
    // model: Retirement
    @Published var ageMinimumLegal     : Int
    @Published var maxReversionRate    : Double
    @Published var decoteParTrimestre  : Double
    @Published var surcoteParTrimestre : Double
    @Published var maxNbTrimestreDecote: Int
    @Published var majorationTauxEnfant: Double
    @Published var ageMinimumAGIRC     : Int
    @Published var valeurDuPointAGIRC  : Double
    @Published var majorationPourEnfant: RegimeAgirc.MajorationPourEnfant
    @Published var newModelSelected    : Bool
    @Published var newTauxReversion    : Double
    @Published var oldReversionModel   : PensionReversion.Old
    // model: Economy
    @Published var inflation         : Double
    @Published var securedRate       : Double
    @Published var stockRate         : Double
    @Published var securedVolatility : Double
    @Published var stockVolatility   : Double
    // model: SocioEconomy
    @Published var pensionDevaluationRate      : Double
    @Published var nbTrimTauxPlein             : Int
    @Published var expensesUnderEvaluationRate : Double

    // MARK: - Initialization
    
    init(using model: Model) {
        menLifeExpectation    = model.humanLife.menLifeExpectationDeterministic
        womenLifeExpectation  = model.humanLife.womenLifeExpectationDeterministic
        nbOfYearsOfdependency = model.humanLife.nbOfYearsOfdependencyDeterministic
        
        ageMinimumLegal      = model.retirement.ageMinimumLegal
        maxReversionRate     = model.retirement.maxReversionRate
        decoteParTrimestre   = model.retirement.decoteParTrimestre
        surcoteParTrimestre  = model.retirement.surcoteParTrimestre
        maxNbTrimestreDecote = model.retirement.maxNbTrimestreDecote
        majorationTauxEnfant = model.retirement.majorationTauxEnfant
        ageMinimumAGIRC      = model.retirement.ageMinimumAGIRC
        valeurDuPointAGIRC   = model.retirement.valeurDuPointAGIRC
        majorationPourEnfant = model.retirement.majorationPourEnfant
        newModelSelected     = model.retirement.newModelSelected
        newTauxReversion     = model.retirement.newTauxReversion
        oldReversionModel    = model.retirement.oldReversionModel

        inflation         = model.economy.inflation
        securedRate       = model.economy.securedRate
        stockRate         = model.economy.stockRate
        securedVolatility = model.economy.securedVolatility
        stockVolatility   = model.economy.stockVolatility
        
        pensionDevaluationRate      = model.socioEconomy.pensionDevaluationRateDeterministic
        nbTrimTauxPlein             = model.socioEconomy.nbTrimTauxPleinDeterministic
        expensesUnderEvaluationRate = model.socioEconomy.expensesUnderEvaluationRateDeterministic
        
        isModified = false
    }
    
    // MARK: - methods
    
    func updateFrom(_ model: Model) {
        menLifeExpectation    = model.humanLife.menLifeExpectationDeterministic
        womenLifeExpectation  = model.humanLife.womenLifeExpectationDeterministic
        nbOfYearsOfdependency = model.humanLife.nbOfYearsOfdependencyDeterministic
        
        ageMinimumLegal      = model.retirement.ageMinimumLegal
        maxReversionRate     = model.retirement.maxReversionRate
        decoteParTrimestre   = model.retirement.decoteParTrimestre
        surcoteParTrimestre  = model.retirement.surcoteParTrimestre
        maxNbTrimestreDecote = model.retirement.maxNbTrimestreDecote
        majorationTauxEnfant = model.retirement.majorationTauxEnfant
        ageMinimumAGIRC      = model.retirement.ageMinimumAGIRC
        valeurDuPointAGIRC   = model.retirement.valeurDuPointAGIRC
        majorationPourEnfant = model.retirement.majorationPourEnfant
        newModelSelected     = model.retirement.newModelSelected
        newTauxReversion     = model.retirement.newTauxReversion

        inflation         = model.economy.inflation
        securedRate       = model.economy.securedRate
        stockRate         = model.economy.stockRate
        securedVolatility = model.economy.securedVolatility
        stockVolatility   = model.economy.stockVolatility

        pensionDevaluationRate      = model.socioEconomy.pensionDevaluationRateDeterministic
        nbTrimTauxPlein             = model.socioEconomy.nbTrimTauxPleinDeterministic
        expensesUnderEvaluationRate = model.socioEconomy.expensesUnderEvaluationRateDeterministic
        
        isModified = false
    }
    
    func update(_ model: Model) {
        model.humanLife.menLifeExpectationDeterministic    = menLifeExpectation
        model.humanLife.womenLifeExpectationDeterministic  = womenLifeExpectation
        model.humanLife.nbOfYearsOfdependencyDeterministic = nbOfYearsOfdependency
        //model.humanLife.persistenceSM.process(event: .onModify)

        model.retirement.ageMinimumLegal      = ageMinimumLegal
        model.retirement.maxReversionRate     = maxReversionRate
        model.retirement.decoteParTrimestre   = decoteParTrimestre
        model.retirement.surcoteParTrimestre  = surcoteParTrimestre
        model.retirement.maxNbTrimestreDecote = maxNbTrimestreDecote
        model.retirement.majorationTauxEnfant = majorationTauxEnfant
        model.retirement.ageMinimumAGIRC      = ageMinimumAGIRC
        model.retirement.valeurDuPointAGIRC   = valeurDuPointAGIRC
        model.retirement.majorationPourEnfant = majorationPourEnfant
        model.retirement.newModelSelected     = newModelSelected
        model.retirement.newTauxReversion     = newTauxReversion
        //model.retirement.persistenceSM.process(event : .onModify)

        model.economy.inflation         = inflation
        model.economy.securedRate       = securedRate
        model.economy.stockRate         = stockRate
        model.economy.securedVolatility = securedVolatility
        model.economy.stockVolatility   = stockVolatility
        //model.economy.persistenceSM.process(event: .onModify)

        model.socioEconomy.pensionDevaluationRateDeterministic      = pensionDevaluationRate
        model.socioEconomy.nbTrimTauxPleinDeterministic             = nbTrimTauxPlein
        model.socioEconomy.expensesUnderEvaluationRateDeterministic = expensesUnderEvaluationRate
        //model.socioEconomy.persistenceSM.process(event: .onModify)

        isModified = false
    }
    
    func update(_ family: Family) {
        family.updateMembersDterministicValues(
            menLifeExpectation,
            womenLifeExpectation,
            nbOfYearsOfdependency,
            ageMinimumLegal,
            ageMinimumAGIRC)
    }
}
