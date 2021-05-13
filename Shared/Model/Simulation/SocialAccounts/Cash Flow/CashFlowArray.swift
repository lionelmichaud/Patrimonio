//
//  CashFlowArray.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Disk

// MARK: - CashFlowArray: Table des cash flow annuels

typealias CashFlowArray = [CashFlowLine]

// MARK: - CashFlowArray extension for CSV export

extension CashFlowArray: CashFlowVisitable {
    func accept(_ visitor: CashFlowVisitor) {
        visitor.visit(element: self)
    }
}

extension CashFlowArray {
    /// Rend la ligne de Cash Flow pour une année donnée
    /// - Parameter year: l'année recherchée
    /// - Returns: le cash flow de l'année
    subscript(year: Int) -> CashFlowLine? {
        self.first { line in
            line.year == year
        }
    }
}
