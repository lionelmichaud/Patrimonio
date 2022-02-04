//
//  ModelDeterministicViewModel.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 01/08/2021.
//

import Foundation
import ModelEnvironment
import RetirementModel
import EconomyModel
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
    @Published var humanLifeModel    : HumanLife.Model
    // model: Retirement
    @Published var retirementModel   : Retirement.Model
    // model: SocioEconomy
    @Published var socioEconomyModel : SocioEconomy.Model
    // model: Fiscal
    @Published var fiscalModel       : Fiscal.Model
    // model: Chômage
    @Published var unemploymentModel : Unemployment.Model
    // model: Economy
    @Published var economyModel      : Economy.Model

    // MARK: - Initialization
    
    init(using model: Model) {
        humanLifeModel    = model.humanLifeModel
        retirementModel   = model.retirementModel
        socioEconomyModel = model.socioEconomyModel
        fiscalModel       = model.fiscalModel
        unemploymentModel = model.unemploymentModel
        economyModel      = model.economyModel

        isModified = false
    }
    
    // MARK: - methods
    
    func updateFrom(_ model: Model) {
        humanLifeModel    = model.humanLifeModel
        retirementModel   = model.retirementModel
        socioEconomyModel = model.socioEconomyModel
        fiscalModel       = model.fiscalModel
        unemploymentModel = model.unemploymentModel
        economyModel      = model.economyModel

        isModified = false
    }
    
    func update(_ model: Model) {
        model.humanLifeModel    = humanLifeModel
        model.retirementModel   = retirementModel
        model.socioEconomyModel = socioEconomyModel
        model.fiscalModel       = fiscalModel
        model.unemploymentModel = unemploymentModel
        model.economyModel      = economyModel

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
