import Foundation
import Statistics
import EconomyModel
import SocioEconomyModel
import NamedValue
import Persistence

// MARK: - BalanceSheetArray: Table des Bilans annuels

public typealias BalanceSheetArray = [BalanceSheetLine]

public extension BalanceSheetArray {
    /// Rend la ligne de Cash Flow pour une année donnée
    /// - Parameter year: l'année recherchée
    /// - Returns: le cash flow de l'année
    subscript(year: Int) -> BalanceSheetLine? {
        self.first { line in
            line.year == year
        }
    }

    /// Construction de la légende du graphique
    /// - Parameter combination: sélection de la catégories de séries à afficher
    /// - Returns: tableau des libéllés des sries des catégories sélectionnées
    func getBalanceSheetLegend(_ combination: BalanceCombination = .both)
    -> ItemSelectionList {
        let firstLine   = self.first!
        switch combination {
            case .assets:
                return firstLine
                    .assets[AppSettings.shared.allPersonsLabel]!
                    .summary
                    .namedValues
                    .map {($0.name, true)} // sélectionné par défaut
            
            case .liabilities:
                return firstLine
                    .liabilities[AppSettings.shared.allPersonsLabel]!
                    .summary
                    .namedValues
                    .map {($0.name, true)} // sélectionné par défaut
            
            case .both:
                return getBalanceSheetLegend(.assets) + getBalanceSheetLegend(.liabilities)
        }
    }
}

// MARK: - Extensions for VISITORS

extension BalanceSheetArray: BalanceSheetCsvVisitableP {
     public func accept(_ visitor: BalanceSheetCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension BalanceSheetArray: BalanceSheetLineChartVisitableP {
    public func accept(_ visitor: BalanceSheetLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension BalanceSheetArray: BalanceSheetStackedBarChartVisitableP {
    public func accept(_ visitor: BalanceSheetStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension BalanceSheetArray: BalanceSheetCategoryStackedBarChartVisitableP {
    public func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
