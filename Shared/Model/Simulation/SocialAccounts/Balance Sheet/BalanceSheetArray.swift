import Foundation
import Statistics
import EconomyModel
import SocioEconomyModel
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CsvBuilder")

// MARK: - BalanceSheetArray: Table des Bilans annuels

typealias BalanceSheetArray = [BalanceSheetLine]

// MARK: - BalanceSheetArray extension for CSV export

extension BalanceSheetArray: BalanceSheetVisitable {
     func accept(_ visitor: BalanceSheetVisitor) {
        visitor.visit(element: self)
    }
}

extension BalanceSheetArray {
    /// Rend la ligne de Cash Flow pour une année donnée
    /// - Parameter year: l'année recherchée
    /// - Returns: le cash flow de l'année
    subscript(year: Int) -> BalanceSheetLine? {
        self.first { line in
            line.year == year
        }
    }
}
