//
//  ModelDeterministicViewModel.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 01/08/2021.
//

import Foundation
import ModelEnvironment

// MARK: - Deterministic View Model

class DeterministicViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var isModified : Bool
    // model: HumanLife
    @Published var menLifeExpectation    : Int
    @Published var womenLifeExpectation  : Int
    @Published var nbOfYearsOfdependency : Int
    // model: Retirement
    @Published var ageMinimumLegal    : Int
    @Published var ageMinimumAGIRC    : Int
    @Published var valeurDuPointAGIRC : Double
    // model: Economy
    @Published var inflation         : Double
    @Published var securedRate       : Double
    @Published var stockRate         : Double
    // model: SocioEconomy
    @Published var pensionDevaluationRate      : Double
    @Published var nbTrimTauxPlein             : Int
    @Published var expensesUnderEvaluationRate : Double

    // MARK: - Initialization
    
    init(using model: Model) {
        menLifeExpectation    = model.humanLife.menLifeExpectationDeterministic
        womenLifeExpectation  = model.humanLife.womenLifeExpectationDeterministic
        nbOfYearsOfdependency = model.humanLife.nbOfYearsOfdependencyDeterministic
        ageMinimumLegal    = model.retirement.ageMinimumLegal
        ageMinimumAGIRC    = model.retirement.ageMinimumAGIRC
        valeurDuPointAGIRC = model.retirement.valeurDuPointAGIRC
        inflation         = model.economy.inflation
        securedRate       = model.economy.securedRate
        stockRate         = model.economy.stockRate
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
        ageMinimumLegal    = model.retirement.ageMinimumLegal
        ageMinimumAGIRC    = model.retirement.ageMinimumAGIRC
        valeurDuPointAGIRC = model.retirement.valeurDuPointAGIRC
        inflation         = model.economy.inflation
        securedRate       = model.economy.securedRate
        stockRate         = model.economy.stockRate
        pensionDevaluationRate      = model.socioEconomy.pensionDevaluationRateDeterministic
        nbTrimTauxPlein             = model.socioEconomy.nbTrimTauxPleinDeterministic
        expensesUnderEvaluationRate = model.socioEconomy.expensesUnderEvaluationRateDeterministic
        
        isModified = false
    }
    
    func update(_ model: Model) {
        model.humanLife.menLifeExpectationDeterministic    = menLifeExpectation
        model.humanLife.womenLifeExpectationDeterministic  = womenLifeExpectation
        model.humanLife.nbOfYearsOfdependencyDeterministic = nbOfYearsOfdependency
        model.retirement.ageMinimumLegal    = ageMinimumLegal
        model.retirement.ageMinimumAGIRC    = ageMinimumAGIRC
        model.retirement.valeurDuPointAGIRC = valeurDuPointAGIRC
        model.economy.inflation         = inflation
        model.economy.securedRate       = securedRate
        model.economy.stockRate         = stockRate
        model.socioEconomy.pensionDevaluationRateDeterministic      = pensionDevaluationRate
        model.socioEconomy.nbTrimTauxPleinDeterministic             = nbTrimTauxPlein
        model.socioEconomy.expensesUnderEvaluationRateDeterministic = expensesUnderEvaluationRate

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
