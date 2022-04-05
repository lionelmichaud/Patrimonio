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
