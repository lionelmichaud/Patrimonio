//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 02/01/2022.
//

import Foundation
import AppFoundation
import NamedValue
import Ownership

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

public protocol RiskQuotableP {
    var riskLevel: RiskLevel? { get }
}

let riskScale = DiscreteScale(scale       : [0.0, 20.0, 40.0, 60.0, 80.0],
                              scaleOrder  : .ascending,
                              firstRating : 0)

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

public protocol LiquidityQuotableP {
    var liquidityLevel: LiquidityLevel? { get }
}

// MARK: - Protocol d'évaluation des niveaux de risque & liquidité

public typealias QuotableP = RiskQuotableP & LiquidityQuotableP
public typealias QuotableNameableValuableP = QuotableP & NameableValuableP & OwnableP

// MARK: - Extensions de Array

public extension Array where Element: QuotableNameableValuableP {
    /// Somme de toutes les valeurs d'un Array pour un niveau de risque donné
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - risk: niveau de risque
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
    /// Somme de toutes les valeurs d'un Array pour un niveau de risque donné et une personne donnée
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: année d'évaluation
    ///   - risk: niveau de risque
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
    /// - Returns: Somme de toutes les valeurs pour un niveau de risque donné
    func sumOfValues (ownedBy ownerName : String,
                      atEndOf year      : Int,
                      witRiskLevel risk : RiskLevel,
                      evaluationContext : EvaluationContext) -> Double {
        return reduce(.zero, {result, element in
            if element.riskLevel == risk {
                return result + element.ownedValue(by                : ownerName,
                                                   atEndOf           : year,
                                                   evaluationContext : evaluationContext)
            } else {
                return result
            }
        })
    }
    /// Somme de toutes les valeurs d'un Array pour un niveau de liquidité donné
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - liquidity: niveau de liquidité
    /// - Returns: Somme de toutes les valeurs pour un niveau de liquidité donné
    func sumOfValues (atEndOf year                : Int,
                      witLiquidityLevel liquidity : LiquidityLevel) -> Double {
        return reduce(.zero, {result, element in
            if element.liquidityLevel == liquidity {
                return result + element.value(atEndOf: year)
            } else {
                return result
            }
        })
    }
    /// Somme de toutes les valeurs d'un Array pour un niveau de liquidité donné et une personne donnée
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: année d'évaluation
    ///   - liquidity: niveau de liquidité
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
    /// - Returns: Somme de toutes les valeurs pour un niveau de liquidité donné
    func sumOfValues (ownedBy ownerName           : String,
                      atEndOf year                : Int,
                      witLiquidityLevel liquidity : LiquidityLevel,
                      evaluationContext           : EvaluationContext) -> Double {
        return reduce(.zero, {result, element in
            if element.liquidityLevel == liquidity {
                return result + element.ownedValue(by                : ownerName,
                                                   atEndOf           : year,
                                                   evaluationContext : evaluationContext)
            } else {
                return result
            }
        })
    }
    /// Somme de toutes les valeurs d'un Array pour un niveau de liquidité/risque donné
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - risk: niveau de risque
    ///   - liquidity: niveau de liquidité
    /// - Returns: Somme de toutes les valeurs pour un niveau de liquidité/risque donné
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
    /// Somme de toutes les valeurs d'un Array pour un niveau de liquidité/risque donné et une personne donnée
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: année d'évaluation
    ///   - risk: niveau de risque
    ///   - liquidity: niveau de liquidité
    ///   - evaluationContext: méthode d'évaluation de la valeure des bien
   /// - Returns: Somme de toutes les valeurs pour un niveau de liquidité/risque donné
    func sumOfValues (ownedBy ownerName           : String,
                      atEndOf year                : Int,
                      witRiskLevel risk           : RiskLevel,
                      witLiquidityLevel liquidity : LiquidityLevel,
                      evaluationContext           : EvaluationContext) -> Double {
        return reduce(.zero, {result, element in
            if element.liquidityLevel == liquidity &&
                element.riskLevel == risk {
                return result + element.ownedValue(by                : ownerName,
                                                   atEndOf           : year,
                                                   evaluationContext : evaluationContext)
            } else {
                return result
            }
        })
    }
}
