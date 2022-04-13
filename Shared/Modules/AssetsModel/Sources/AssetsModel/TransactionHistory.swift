//
//  TransactionHistory.swift
//  
//
//  Created by Lionel MICHAUD on 13/04/2022.
//

import Foundation
import AppFoundation

/// Historique des transactions d'achat ou de vente
public typealias TransactionHistory = [TransactionOrder]

extension TransactionHistory {

    public var earliestBuyingDate : Date {
        self.min(by: { $0.date < $1.date })?.date ?? Date.distantFuture
    }

    public var latestBuyingDate : Date {
        self.max(by: { $0.date < $1.date })?.date ?? Date.distantFuture
    }

    public var averagePrice: Double {
        guard totalQuantity != 0 else {
            return 0
        }
        return totalInvestment / totalQuantity.double()
    }

    public var totalInvestment: Double {
        var total = 0.0
        for transaction in self {
            total += transaction.unitPrice * transaction.quantity.double()
        }
        return total
    }

    public var totalQuantity: Int {
        self.sum(for: \.quantity)
    }
}

extension TransactionHistory: ValidableP {
    public var isValid: Bool {
        self.allSatisfy { $0.isValid }
    }
}

/// Transaction d'achat ou de vente
public struct TransactionOrder: Identifiable, Codable, Equatable, ValidableP {
    enum CodingKeys: CodingKey {
        case quantity
        case unitPrice
        case date
    }

    public var id = UUID()
    public var quantity  : Int    = 0
    public var unitPrice : Double = 0
    public var date      : Date   = Date.now

    public var amount: Double {
        unitPrice * quantity.double()
    }

    public var isValid: Bool {
        unitPrice.isPOZ
    }

    public init(quantity  : Int    = 0,
                unitPrice : Double = 0,
                date      : Date   = Date.now) {
        self.quantity  = quantity
        self.unitPrice = unitPrice
        self.date      = date
    }
}

