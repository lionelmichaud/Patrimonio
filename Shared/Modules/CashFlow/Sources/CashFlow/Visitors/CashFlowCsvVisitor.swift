//
//  CSV Visitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 09/05/2021.
//

import Foundation
import os
import NamedValue
import EconomyModel
import Statistics

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CsvCashFlowTableVisitor")

// MARK: - VISITOR: constructeur de table de CASH FLOW

/// Concrete Visitors implement several versions of the same algorithm, which
/// can work with all concrete component classes.
///
/// You can experience the biggest benefit of the Visitor pattern when using it
/// with a complex object structure, such as a Composite tree. In this case, it
/// might be helpful to store some intermediate state of the algorithm while
/// executing visitor's methods over various objects of the structure.
public final class CashFlowCsvTableVisitor: CashFlowCsvVisitorP {

    private var table  = ""
    private let mode: SimulationModeEnum

    public init(withMode mode: SimulationModeEnum) {
        self.mode = mode
    }
    
    /// Construire la ligne de revenus de la SCI
    /// - Parameter element: Revenus de la SCI
    public func buildCsv(element: SciCashFlowLine.Revenues) {
        let sciDividends = element.scpiDividends
        // For every element , extract the values as a comma-separated string.
        table.append(sciDividends.namedValues
                        .map { $0.value.roundedString }
                        .joined(separator: ";"))
        // total des DIVIDENDES
        table.append(";\(sciDividends.total.roundedString);")

        let sciSales = element.scpiSale
        // For every element , extract the values as a comma-separated string.
        table.append(sciSales.namedValues
                        .map { $0.value.roundedString }
                        .joined(separator: ";"))
        // total des VENTES
        table.append(";\(sciSales.total.roundedString);")
    }
    
    /// IS et Revenus Net d'IS de la SCI
    /// - Parameter element: Revenus de la SCI
    public func buildCsv(element: SciCashFlowLine) {
        element.revenues.accept(self)
        
        table.append("\((-element.IS).roundedString);")
        table.append("\(element.netRevenues.roundedString);")
    }
    
    /// Construction de la tables des revenus hors SCI
    /// - Parameter element: Agrégat des revenus hors SCI
    public func buildCsv(element: ValuedRevenues) {
        // pour chaque catégorie
        RevenueCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let revenuesInCategory = element[category] else { return }

            let namedValues = revenuesInCategory.credits.namedValues
            table.append(namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: ";"))
            // valeure cumulée de la catégorie
            table.append(";\(revenuesInCategory.credits.total.roundedString);")
        }
        
        // total des REVENUS
        table.append("\(element.totalRevenue.roundedString);")
    }

    public func buildCsv(element: ValuedTaxes) {
        // For every element , extract the values as a comma-separated string.
        TaxeCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let taxesInCategory = element[category] else { return }

            let namedValues = taxesInCategory.namedValues
            table.append(namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: ";"))
            // valeure cumulée de la catégorie
            table.append(";\(taxesInCategory.total.roundedString);")
        }
        table.append("\(element.total.roundedString);")
    }
    
    public func buildCsv(element: CashFlowLine) {
        /// Revenus des parents
        func visitRevenues() {
            // visiter l'ensembles des revenus de la famille
            let valuedRevenues = element.adultsRevenues
            valuedRevenues.accept(self)
        }

        /// Revenus de la SCI
        func visitSCI() {
            element.sciCashFlowLine.accept(self)
        }
        
        /// Dépenses de vie des parents
        func visitExpenses() {
            let lifeExpenses = element.lifeExpenses
            // For every element , extract the values as a comma-separated string.
            table.append(lifeExpenses.namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: ";"))
            // total des DEPENSES
            table.append(";\(lifeExpenses.total.roundedString);")
        }
        
        /// Taxes des parents
        func visitTaxes() {
            let valuedTaxes = element.adultTaxes
            table.append("\(valuedTaxes.irpp.familyQuotient.roundedString);")

            valuedTaxes.accept(self)
        }

        func visitDebts() {
            // quotient familial
            let debts = element.debtPayements
            // For every element , extract the values as a comma-separated string.
            table.append(debts.namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: ";"))
            // total des DETTES
            table.append(";\(debts.total.roundedString);")
        }

        func visitInvestements() {
            let investPayements = element.investPayements
            // For every element , extract the values as a comma-separated string.
            table.append(investPayements.namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: ";"))
            // total des INVESTISSEMENTS
            table.append(";\(investPayements.total.roundedString);")
        }

        // année
        table.append("\(element.year);")

        // ages
        table.append(element.ages.persons
                        .map { String($0.age) }
                        .joined(separator: ";"))
        table.append(";")
        
        // construire la partie Revenus du tableau
        visitRevenues()
        visitSCI()

        // somme des rentrées de trésorerie
        table.append("\(element.sumOfAdultsRevenues.roundedString);")

        visitExpenses()
        visitTaxes()
        visitDebts()
        visitInvestements()

        // somme des sorties de trésoreries
        table.append("\(element.sumOfAdultsExpenses.roundedString);")

        // Net cashflow
        table.append("\(element.netAdultsCashFlow.roundedString)")
    }

    public func buildCsv(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else {
            customLog.log(level: .info, "Pas de cash flow à exporter au format CSV \(Self.self, privacy: .public)")
            return
        }

        // construire le tableau de valeurs: une ligne par année
        for idx in element.indices {
            element[idx].accept(self)
            table.append("\n")
        }
    }
}

extension CashFlowCsvTableVisitor: CustomStringConvertible {
    public var description: String {
        return table
    }
}
