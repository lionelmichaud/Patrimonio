//
//  AdultViewModel.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 28/04/2021.
//

import SwiftUI
import FiscalModel
import UnemployementModel
import RetirementModel
import ModelEnvironment
import PersonModel

// MARK: - Adult View Model

final class AdultViewModel: ObservableObject {
    @Published var fiscalOption              = InheritanceFiscalOption.fullUsufruct
    @Published var dateRetirement            = Date()
    @Published var causeOfRetirement         = Unemployment.Cause.demission
    @Published var hasAllocationSupraLegale  = false
    @Published var allocationSupraLegale     = 0.0
    //@Published var dateOfEndOfUnemployAlloc  = Date()
    @Published var ageAgircPension           = 0
    @Published var moisAgircPension          = 0
    @Published var agePension                = 0
    @Published var moisPension               = 0
    @Published var nbYearOfDepend            = 0
    @Published var revIndex                  = 0
    @Published var revenueBrut               = 0.0
    @Published var revenueTaxable            = 0.0
    @Published var revenueNet                = 0.0
    @Published var fromDate                  = Date.now
    @Published var insurance                 = 0.0
    @Published var lastKnownPensionSituation = RegimeGeneralSituation()
    @Published var lastKnownAgircSituation   = RegimeAgircSituation()

    // MARK: - Initializers of ViewModel from Model
    
    init(from model: Model) {
        ageAgircPension = model.retirementModel.regimeAgirc.ageMinimum
        agePension      = model.retirementModel.regimeGeneral.ageMinimumLegal
    }

    init(from adult: Adult) {
        fiscalOption              = adult.fiscalOption
        dateRetirement            = adult.dateOfRetirement
        causeOfRetirement         = adult.causeOfRetirement
        hasAllocationSupraLegale  = adult.layoffCompensationBonified != nil
        allocationSupraLegale     = adult.layoffCompensationBonified ?? 0.0
        nbYearOfDepend            = adult.nbOfYearOfDependency
        ageAgircPension           = adult.ageOfAgircPensionLiquidComp.year!
        moisAgircPension          = adult.ageOfAgircPensionLiquidComp.month!
        agePension                = adult.ageOfPensionLiquidComp.year!
        moisPension               = adult.ageOfPensionLiquidComp.month!
        lastKnownPensionSituation = adult.lastKnownPensionSituation
        lastKnownAgircSituation   = adult.lastKnownAgircPensionSituation
        switch adult.workIncome {
            case let .salary(brutSalary, taxableSalary, netSalary, fromDate, healthInsurance):
                revenueBrut    = brutSalary
                revenueTaxable = taxableSalary
                revenueNet     = netSalary
                self.fromDate  = fromDate
                insurance      = healthInsurance
                revIndex       = WorkIncomeType.salaryId
            case let .turnOver(BNC, incomeLossInsurance):
                revenueBrut = BNC
                revenueNet  = BNC
                insurance   = incomeLossInsurance
                revIndex    = WorkIncomeType.turnOverId
            case .none:
                revenueBrut    = 0
                revenueTaxable = 0
                revenueNet     = 0
                insurance      = 0
                revIndex       = 0
        }
    }

    init() {
    }

    func update(adult: Adult) {
        let workIncome: WorkIncomeType
        if revIndex == WorkIncomeType.salaryId {
            workIncome =
                WorkIncomeType.salary(brutSalary      : revenueBrut,
                                      taxableSalary   : revenueTaxable,
                                      netSalary       : revenueNet,
                                      fromDate        : fromDate,
                                      healthInsurance : insurance)
        } else {
            workIncome =
                WorkIncomeType.turnOver(BNC                 : revenueBrut,
                                        incomeLossInsurance : insurance)
        }

        let layoffCompensationBonified: Double?
        if causeOfRetirement == Unemployment.Cause.demission {
            // pas d'indemnité de licenciement en cas de démission
            layoffCompensationBonified = nil
        } else {
            if hasAllocationSupraLegale {
                // indemnité supra-légale de licenciement accordée par l'employeur
                layoffCompensationBonified = allocationSupraLegale
            } else {
                // pas d'indemnité supra-légale de licenciement
                layoffCompensationBonified = nil
            }
        }
        
        AdultBuilder(for: adult)
            .receivesWorkIncome(workIncome)
            .willCeaseActivities(on     : dateRetirement,
                                 dueTo  : causeOfRetirement,
                                 withLayoffCompensationBonified : layoffCompensationBonified)
            .willLiquidPension(atAge: (year: agePension, month: moisPension, day:0),
                               lastKnownSituation: lastKnownPensionSituation)
            .willLiquidAgircPension(atAge: (year: ageAgircPension, month: moisAgircPension, day:0),
                                    lastKnownSituation: lastKnownAgircSituation)
            .willFaceDependencyDuring(nbYearOfDepend)
            .adoptsSuccessionFiscalOption(fiscalOption)
    }
}
