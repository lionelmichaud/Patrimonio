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
/// revenus du travail
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

// MARK: - Extensions

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
