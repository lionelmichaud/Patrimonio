//
//  InvestmentRate.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 14/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Type d'investissement

public enum InterestRateKind: Codable {
    case contractualRate (fixedRate: Double)
    case marketRate (stockRatio: Double)
    
    // properties
    
    public static var allCases: [InterestRateKind] {
        return [.contractualRate(fixedRate: 0.0),
                .marketRate(stockRatio: 0.0)]
    }
    
    @available(*, unavailable)
    case all
    
    public var rawValue: Int {
        rawValueGeneric(of: self)
    }
}

// MARK: - Extensions

extension InterestRateKind: PickableIdentifiableEnumP {
    public var id: Int {
        return self.rawValue
    }
    
    public var pickerString: String {
        switch self {
            case .contractualRate:
                return "Taux Contractuel"
                
            case .marketRate:
                return "Taux de Marché"
        }
    }
    
}

extension InterestRateKind: CustomStringConvertible {
    public var description: String {
        switch self {
            case .contractualRate(let fixedRate):
                return "Taux Contractuel = \(fixedRate) %"
                
            case .marketRate(let stockRatio):
                return "Taux de Marché avec \(stockRatio) % d'actions et \(100 - stockRatio) % d'obligations"
        }
    }
}
