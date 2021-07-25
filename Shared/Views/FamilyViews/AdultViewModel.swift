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

// MARK: - Adult View Model

class AdultViewModel: ObservableObject {
    @Published var fiscalOption              = InheritanceFiscalOption.fullUsufruct
    @Published var dateRetirement            = Date()
    @Published var causeOfRetirement         = Unemployment.Cause.demission
    @Published var hasAllocationSupraLegale  = false
    @Published var allocationSupraLegale     = 0.0
    //@Published var dateOfEndOfUnemployAlloc  = Date()
    @Published var ageAgircPension           = 0
    @Published var trimAgircPension          = 0
    @Published var agePension                = 0
    @Published var trimPension               = 0
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

    init(from adult: Adult) {
        fiscalOption              = adult.fiscalOption
        dateRetirement            = adult.dateOfRetirement
        causeOfRetirement         = adult.causeOfRetirement
        hasAllocationSupraLegale  = adult.layoffCompensationBonified != nil
        allocationSupraLegale     = adult.layoffCompensationBonified ?? 0.0
        nbYearOfDepend            = adult.nbOfYearOfDependency
        ageAgircPension           = adult.ageOfAgircPensionLiquidComp.year!
        trimAgircPension          = adult.ageOfAgircPensionLiquidComp.month! / 3
        agePension                = adult.ageOfPensionLiquidComp.year!
        trimPension               = adult.ageOfPensionLiquidComp.month! / 3
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

    func updateFromViewModel(adult: Adult) {
        adult.fiscalOption      = fiscalOption
        adult.dateOfRetirement  = dateRetirement
        adult.causeOfRetirement = causeOfRetirement
        if causeOfRetirement == Unemployment.Cause.demission {
            // pas d'indemnité de licenciement en cas de démission
            adult.layoffCompensationBonified = nil
        } else {
            if hasAllocationSupraLegale {
                // indemnité supra-légale de licenciement accordée par l'employeur
                adult.layoffCompensationBonified = allocationSupraLegale
            } else {
                // pas d'indemnité supra-légale de licenciement
                adult.layoffCompensationBonified = nil
            }
        }

        adult.setAgeOfPensionLiquidComp(year  : agePension,
                                        month : trimPension * 3)
        adult.setAgeOfAgircPensionLiquidComp(year  : ageAgircPension,
                                             month : trimAgircPension * 3)
        adult.lastKnownPensionSituation = lastKnownPensionSituation
        adult.lastKnownAgircPensionSituation = lastKnownAgircSituation

        if revIndex == WorkIncomeType.salaryId {
            adult.workIncome =
                WorkIncomeType.salary(brutSalary      : revenueBrut,
                                      taxableSalary   : revenueTaxable,
                                      netSalary       : revenueNet,
                                      fromDate        : fromDate,
                                      healthInsurance : insurance)
        } else {
            adult.workIncome =
                WorkIncomeType.turnOver(BNC                 : revenueBrut,
                                        incomeLossInsurance : insurance)
        }
        adult.nbOfYearOfDependency = nbYearOfDepend
    }
}
