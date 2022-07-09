//
//  Income.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Revenus du travail

/// Revenus du travail
public enum WorkIncomeType: Codable {
    case salary (brutSalary: Double, taxableSalary: Double, netSalary: Double, fromDate: Date, healthInsurance: Double)
    case turnOver (BNC: Double, incomeLossInsurance: Double)
    
    @available(*, unavailable)
    case all
    
    public static var allCases: [WorkIncomeType] {
        return [.salary(brutSalary: 0, taxableSalary: 0, netSalary: 0, fromDate: Date.now, healthInsurance: 0),
                .turnOver(BNC: 0, incomeLossInsurance: 0)]
    }
    
    public static var salaryId: Int {
        WorkIncomeType.salary(brutSalary      : 0,
                              taxableSalary   : 0,
                              netSalary       : 0,
                              fromDate        : Date.now,
                              healthInsurance : 0).id
    }
    
    public static var turnOverId: Int {
        WorkIncomeType.turnOver(BNC: 0, incomeLossInsurance: 0).id
    }
    
    public var rawValue: Int {
        rawValueGeneric(of: self)
        //        if Mirror(reflecting: self).children.count != 0 {
        //            // le swich case possède des valeurs
        //            let selfCaseName = Mirror(reflecting: self).children.first!.label!
        //
        //            return PersonalIncomeType.allCases.firstIndex(where: { swichCase in
        //                let switchingCaseName = Mirror(reflecting: swichCase).children.first!.label!
        //                return switchingCaseName == selfCaseName
        //            })!
        //        } else {
        //            return PersonalIncomeType.allCases.firstIndex(where: { swichCase in
        //                return swichCase == self
        //            })!
        //        }
    }
}

extension WorkIncomeType: PickableIdentifiableEnumP {
    public var id: Int {
        return self.rawValue
    }
    
    public var pickerString: String {
        switch self {
            case .salary:
                return "Salaire"
            case .turnOver:
                return "Chiffre d'affaire"
        }
    }
    
    public var description: String {
        switch self {

            case let .salary(brutSalary, taxableSalary, netSalary, fromDate, healthInsurance):
                return
                    """
                    Salaire:
                    - A partir du: \(fromDate.stringMediumDate)
                    - Brut:      \(brutSalary.€String)
                    - Net:       \(netSalary.€String)
                    - Coût annuel mutuelle: \(healthInsurance.€String)
                    - Imposable: \(taxableSalary.€String) (avant abattement)
                    """
                
            case let .turnOver(BNC, incomeLossInsurance):
                return
                    """
                    Chiffre d'affaire:
                    - BNC: \(BNC.€String)
                    - Coût annuel assurance perte de revenu: \(incomeLossInsurance.€String)
                    """
        }
    }
}

// MARK: - Calculs fiscaux relatifs aux revenus du travail

/// Calculs fiscaux relatifs aux revenus du travail
public struct WorkIncomeManager {
    public init() { }

    /// Rrevenu du travail avant charges sociales, dépenses de mutuelle ou d'assurance perte d'emploi
    public func workBrutIncome(from workIncome : WorkIncomeType?) -> Double {
        switch workIncome {
            case .salary(let brutSalary, _, _, _, _):
                return brutSalary
            case .turnOver(let BNC, _):
                return BNC
            case .none:
                return 0
        }
    }

    /// Revenu net de feuille de paye, net de charges sociales et mutuelle obligatore
    public func workNetIncome(from workIncome   : WorkIncomeType?,
                              using fiscalModel : Fiscal.Model) -> Double {
        switch workIncome {
            case .salary(_, _, let netSalary, _, _):
                return netSalary
            case .turnOver(let BNC, _):
                return fiscalModel.turnoverTaxes.net(BNC)
            case .none:
                return 0
        }
    }

    /// Revenu net de feuille de paye et de mutuelle facultative ou d'assurance perte d'emploi
    public func workLivingIncome(from workIncome   : WorkIncomeType?,
                                 using fiscalModel : Fiscal.Model) -> Double {
        switch workIncome {
            case .salary(_, _, let netSalary, _, let charge):
                return netSalary - charge
            case .turnOver(let BNC, let charge):
                return fiscalModel.turnoverTaxes.net(BNC) - charge
            case .none:
                return 0
        }
    }

    /// Revenu taxable à l'IRPP
    public func workTaxableIncome(from workIncome   : WorkIncomeType?,
                                  using fiscalModel : Fiscal.Model) -> Double {
        switch workIncome {
            case .none:
                return 0
            default:
                return fiscalModel.incomeTaxes.taxableIncome(from: workIncome!)
        }
    }
}

// MARK: - Activité professionnelle annexe générant du revenu

/// Activité professionnelle annexe générant du revenu
public struct SideWork: Codable {
    public var workIncome : WorkIncomeType
    public var startDate  : Date
    public var endDate    : Date

    // MARK: - Methods

    /// Revenu net de feuille de paye, net de charges sociales et mutuelle obligatore
    public func workNetIncome(using fiscalModel : Fiscal.Model) -> Double {
        WorkIncomeManager().workNetIncome(from: workIncome,
                                          using: fiscalModel)
    }

    /// Revenu net de feuille de paye et de mutuelle facultative ou d'assurance perte d'emploi
    public func workLivingIncome(using fiscalModel : Fiscal.Model) -> Double {
        WorkIncomeManager().workLivingIncome(from: workIncome,
                                             using: fiscalModel)
    }

    /// Revenu taxable à l'IRPP
    public func workTaxableIncome(using fiscalModel : Fiscal.Model) -> Double {
        WorkIncomeManager().workTaxableIncome(from: workIncome,
                                              using: fiscalModel)
    }

    /// Revenu net de charges pour vivre et revenu taxable à l'IRPP
    /// - Parameter year: année
    public func workIncome(during year       : Int,
                           using fiscalModel : Fiscal.Model)
    -> (net: Double, taxableIrpp: Double) {

        let nbDays = numberOf(.day,
                               from: max(startDate, firstDayOf(year: year)),
                               to: min(endDate, lastDayOf(year: year))).day
        guard let nbDays, nbDays > 0 else {
            return (0, 0)
        }
        let workIncomeManager = WorkIncomeManager()
        let workLivingIncome = workIncomeManager.workLivingIncome(from : workIncome,
                                                                  using: fiscalModel)
        let workTaxableIncome = workIncomeManager.workTaxableIncome(from : workIncome,
                                                                    using: fiscalModel)
        return (net         : workLivingIncome  * Double(nbDays) / 365,
                taxableIrpp : workTaxableIncome * Double(nbDays) / 365)
    }
}

extension SideWork: CustomStringConvertible {
    public var description: String {
        return "Activité professionnelle annexe:\n" +
        "- Revenu:\(workIncome.description)".withPrefixedSplittedLines("  ") + "\n" +
        "- Début :\(startDate.stringMediumDate)".withPrefixedSplittedLines("  ") + "\n" +
        "- Fin   :\(endDate.stringMediumDate)".withPrefixedSplittedLines("  ") + "\n"
    }
}
