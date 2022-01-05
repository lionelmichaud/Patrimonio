//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 02/01/2022.
//

import Foundation
import AppFoundation
import NamedValue

// MARK: - Evaluation du niveau de risque

public enum RiskLevel: Int, Codable, PickableEnumP {
    case veryLow = 0
    case low
    case medium
    case high
    case veryHigh

    public var pickerString: String {
        switch self {
            case .veryLow :
                return "Très faible"
            case .low:
                return "Faible"
            case .medium:
                return "Moyen"
            case .high:
                return "Élevé"
            case .veryHigh:
                return "Très élevé"
        }
    }
}

public protocol RiskQuotable {
    var riskLevel: RiskLevel? { get }
}

// MARK: - Evaluation du niveau de liquidité

public enum LiquidityLevel: Int, Codable, PickableEnumP {
    case low = 0
    case medium
    case high
    
    public var pickerString: String {
        switch self {
            case .low:
                return "Faible"
            case .medium:
                return "Moyenne"
            case .high:
                return "Élevée"
        }
    }
}

public protocol LiquidityQuotable {
    var liquidityLevel: LiquidityLevel? { get }
}

// MARK: - Protocol d'évaluation des niveaux de risque & liquidité

public typealias Quotable = RiskQuotable & LiquidityQuotable
public typealias QuotableNameableValuableP = Quotable & NameableValuableP

// MARK: - Extensions de Array

public extension Array where Element: QuotableNameableValuableP {
    /// Somme de toutes les valeurs d'un Array pour un niveau de risque donné
    /// - Returns: Somme de toutes les valeurs pour un niveau de risque donné
    func sumOfValues (atEndOf year      : Int,
                      witRiskLevel risk : RiskLevel) -> Double {
        return reduce(.zero, {result, element in
            if element.riskLevel == risk {
                return result + element.value(atEndOf: year)
            } else {
                return result
            }
        })
    }
    /// Somme de toutes les valeurs d'un Array pour un niveau de liquidité donné
    /// - Returns: Somme de toutes les valeurs pour un niveau de liquidité donné
    func sumOfValues (atEndOf year : Int,
                      witLiquidityLevel liquidity : LiquidityLevel) -> Double {
        return reduce(.zero, {result, element in
            if element.liquidityLevel == liquidity {
                return result + element.value(atEndOf: year)
            } else {
                return result
            }
        })
    }
    /// Somme de toutes les valeurs d'un Array pour un niveau de liquidité donné
    /// - Returns: Somme de toutes les valeurs pour un niveau de liquidité donné
    func sumOfValues (atEndOf year : Int,
                      witRiskLevel risk : RiskLevel,
                      witLiquidityLevel liquidity : LiquidityLevel) -> Double {
        return reduce(.zero, {result, element in
            if element.liquidityLevel == liquidity &&
                element.riskLevel == risk {
                return result + element.value(atEndOf: year)
            } else {
                return result
            }
        })
    }
}
