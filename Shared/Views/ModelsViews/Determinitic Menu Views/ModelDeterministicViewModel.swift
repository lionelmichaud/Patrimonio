//
//  ModelDeterministicViewModel.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 01/08/2021.
//

import Foundation
import ModelEnvironment
import RetirementModel
import SocioEconomyModel
import FiscalModel
import HumanLifeModel
import UnemployementModel
import FamilyModel

// MARK: - Deterministic View Model

class DeterministicViewModel: ObservableObject {
    
    // MARK: - Properties

    @Published var isModified : Bool
    // model: HumanLife
    @Published var humanLifeModel : HumanLife.Model
    // model: Retirement
    @Published var retirementModel : Retirement.Model
    // model: Economy
    @Published var inflation         : Double
    @Published var securedRate       : Double
    @Published var stockRate         : Double
    @Published var securedVolatility : Double
    @Published var stockVolatility   : Double
    // model: SocioEconomy
    @Published var socioEconomyModel : SocioEconomy.Model
    // model: Fiscal
    @Published var fiscalModel : Fiscal.Model
    // model: Chômage
    @Published var unemploymentModel : Unemployment.Model

    // MARK: - Initialization
    
    init(using model: Model) {
        humanLifeModel    = model.humanLifeModel
        retirementModel   = model.retirementModel
        socioEconomyModel = model.socioEconomyModel
        fiscalModel       = model.fiscalModel
        unemploymentModel = model.unemploymentModel

        inflation         = model.economy.inflation
        securedRate       = model.economy.securedRate
        stockRate         = model.economy.stockRate
        securedVolatility = model.economy.securedVolatility
        stockVolatility   = model.economy.stockVolatility

        isModified = false
    }
    
    // MARK: - methods
    
    func updateFrom(_ model: Model) {
        humanLifeModel    = model.humanLifeModel
        retirementModel   = model.retirementModel
        socioEconomyModel = model.socioEconomyModel
        fiscalModel       = model.fiscalModel
        unemploymentModel = model.unemploymentModel

        inflation         = model.economy.inflation
        securedRate       = model.economy.securedRate
        stockRate         = model.economy.stockRate
        securedVolatility = model.economy.securedVolatility
        stockVolatility   = model.economy.stockVolatility

        isModified = false
    }
    
    func update(_ model: Model) {
        model.humanLifeModel    = humanLifeModel
        model.retirementModel   = retirementModel
        model.socioEconomyModel = socioEconomyModel
        model.fiscalModel       = fiscalModel
        model.unemploymentModel = unemploymentModel

        model.economy.inflation         = inflation
        model.economy.securedRate       = securedRate
        model.economy.stockRate         = stockRate
        model.economy.securedVolatility = securedVolatility
        model.economy.stockVolatility   = stockVolatility

        isModified = false
    }
    
    func update(_ family: Family) {
        family.updateMembersDterministicValues(
            Int(humanLifeModel.menLifeExpectation.defaultValue.rounded()),
            Int(humanLifeModel.womenLifeExpectation.defaultValue.rounded()),
            Int(humanLifeModel.nbOfYearsOfdependency.defaultValue.rounded()),
            retirementModel.regimeGeneral.ageMinimumLegal,
            retirementModel.regimeAgirc.ageMinimum)
    }
}
