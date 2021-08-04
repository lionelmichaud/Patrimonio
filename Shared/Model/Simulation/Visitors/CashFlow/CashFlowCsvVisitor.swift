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
class CashFlowCsvTableVisitor: CashFlowCsvVisitorP {

    private var table  = ""
    private let mode: SimulationModeEnum

    internal init(withMode mode: SimulationModeEnum) {
        self.mode = mode
    }

    func buildCsv(element: SciCashFlowLine.Revenues) {
        // For every element , extract the values as a comma-separated string.
        let sciDividends = element.scpiDividends
        // For every element , extract the values as a comma-separated string.
        table.append(sciDividends.namedValues
                        .map { $0.value.roundedString }
                        .joined(separator: "; "))
        // total des DIVIDENDES
        table.append("; \(sciDividends.total.roundedString); ")

        let sciSales = element.scpiSale
        // For every element , extract the values as a comma-separated string.
        table.append(sciSales.namedValues
                        .map { $0.value.roundedString }
                        .joined(separator: "; "))
        // total des VENTES
        table.append("; \(sciSales.total.roundedString); ")
    }

    func buildCsv(element: SciCashFlowLine) {
        element.revenues.accept(self)
        table.append("\((-element.IS).roundedString); ")
        table.append("\(element.netRevenues.roundedString); ")
    }

    func buildCsv(element: ValuedRevenues) {
        // pour chaque catégorie
        RevenueCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let revenuesInCategory = element[category] else { return }

            let namedValues = revenuesInCategory.credits.namedValues
            table.append(namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: "; "))
            // valeure cumulée de la catégorie
            table.append("; \(revenuesInCategory.credits.total.roundedString);")
        }
    }

    func buildCsv(element: ValuedTaxes) {
        // For every element , extract the values as a comma-separated string.
        TaxeCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let taxesInCategory = element[category] else { return }

            let namedValues = taxesInCategory.namedValues
            table.append(namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: "; "))
            // valeure cumulée de la catégorie
            table.append("; \(taxesInCategory.total.roundedString);")
        }
        table.append("\(element.total.roundedString); ")
    }

    func buildCsv(element: CashFlowLine) {
        func visitRevenues() {
            // visiter l'ensembles des revenus de la famille
            let valuedRevenues = element.adultsRevenues
            valuedRevenues.accept(self)
            // total des REVENUS
            table.append("\(valuedRevenues.totalRevenue.roundedString); ")
            // revenus reporté de l'année précédente
            table.append("\(valuedRevenues.taxableIrppRevenueDelayedFromLastYear.value(atEndOf :0).roundedString); ")
        }

        func visitSCI() {
            element.sciCashFlowLine.accept(self)
        }

        func visitExpenses() {
            let lifeExpenses = element.lifeExpenses
            // For every element , extract the values as a comma-separated string.
            table.append(lifeExpenses.namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: "; "))
            // total des DEPENSES
            table.append("; \(lifeExpenses.total.roundedString); ")
        }

        func visitTaxes() {
            let valuedTaxes = element.adultTaxes
            table.append("\(valuedTaxes.irpp.familyQuotient.roundedString); ")

            valuedTaxes.accept(self)
            // total des TAXES
            table.append("\(valuedTaxes.total.roundedString); ")
        }

        func visitDebts() {
            // quotient familial
            let debts = element.debtPayements
            // For every element , extract the values as a comma-separated string.
            table.append(debts.namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: "; "))
            // total des DETTES
            table.append("\(debts.total.roundedString); ")
        }

        func visitInvestements() {
            let investPayements = element.investPayements
            // For every element , extract the values as a comma-separated string.
            table.append(investPayements.namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: "; "))
            // total des INVESTISSEMENTS
            table.append("; \(investPayements.total.roundedString); ")
        }

        // année
        table.append("\(element.year); ")

        // ages
        table.append(element.ages.persons
                        .map { String($0.age) }
                        .joined(separator: "; "))
        table.append(";")
        
        // construire la partie Revenus du tableau
        visitRevenues()
        visitSCI()

        // somme des rentrées de trésorerie
        table.append("\(element.sumOfRevenues.roundedString); " )

        visitExpenses()
        visitTaxes()
        visitDebts()
        visitInvestements()

        // somme des sorties de trésoreries
        table.append("\(element.sumOfExpenses.roundedString); " )

        // Net cashflow
        table.append("\(element.netCashFlow.roundedString)" )
    }

    func buildCsv(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else {
            customLog.log(level: .info, "Pas de cash flow à exporter au format CSV \(Self.self, privacy: .public)")
            return
        }

        // construire le tableau de valeurs: une ligne par année
        for idx in element.range {
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

// MARK: - VISITOR: constructeur d'entête de table de CASH FLOW

class CashFlowCsvHeaderVisitor: CashFlowCsvVisitorP {

    private var header1  = ""
    private var header2  = ""

    func buildCsv(element: SciCashFlowLine.Revenues) {
        // For every element , extract the values as a comma-separated string.
        let sciDividends = element.scpiDividends
        // For every element , extract the values as a comma-separated string.
        header1.append(sciDividends.namedValues
                        .map { _ in sciDividends.tableName.uppercased() }
                        .joined(separator: "; "))
        header2.append(sciDividends.namedValues
                        .map { $0.name }
                        .joined(separator: "; "))
        // total des DIVIDENDES
        header1.append("; ; ")
        header2.append("; \(sciDividends.tableName.uppercased()) TOTAL; ")

        let sciSales = element.scpiSale
        // For every element , extract the values as a comma-separated string.
        header1.append(sciSales.namedValues
                        .map { _ in sciSales.tableName.uppercased() }
                        .joined(separator: "; "))
        header2.append(sciSales.namedValues
                        .map { $0.name }
                        .joined(separator: "; "))
        // total des VENTES
        header1.append("; ; ")
        header2.append("; \(sciSales.tableName.uppercased()) TOTAL; ")
    }

    func buildCsv(element: SciCashFlowLine) {
        element.revenues.accept(self)

        header1.append("REVENU SCI; ")
        header2.append("IS; ")

        header1.append("REVENU SCI; ")
        header2.append("NET; ")
    }

    func buildCsv(element: ValuedRevenues) {
        // pour chaque catégorie
        RevenueCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let revenuesInCategory = element[category] else { return }

            let namedValues = revenuesInCategory.credits.namedValues
            header1.append(namedValues
                            .map { _ in category.rawValue.uppercased() }
                            .joined(separator: "; "))
            header2.append(namedValues
                            .map { $0.name }
                            .joined(separator: "; "))
            // valeure cumulée de la catégorie
            header1.append("; ; ")
            header2.append("; \(revenuesInCategory.credits.tableName.uppercased()) TOTAL; ")
        }
        // total des REVENUS
        header1.append("; ")
        header2.append("REVENU PERCU TOTAL; ")
        // revenus reporté de l'année précédente
        header1.append("REVENU; ")
        header2.append("\(element.taxableIrppRevenueDelayedFromLastYear.name); ")
    }

    func buildCsv(element: ValuedTaxes) {
        // For every element , extract the values as a comma-separated string.
        TaxeCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let taxesInCategory = element[category] else { return }

            let namedValues = taxesInCategory.namedValues
            header1.append(namedValues
                            .map({ _ in category.rawValue.uppercased() })
                            .joined(separator: "; "))
            header2.append(namedValues
                            .map { $0.name }
                            .joined(separator: "; "))
            // valeure cumulée de la catégorie
            header1.append("; ; ")
            header2.append("; \(taxesInCategory.tableName.uppercased()) TOTAL; ")
        }
        // total des TAXES
        header1.append("; ")
        header2.append("IMPOTS & TAXES TOTAL; ")
    }

    func buildCsv(element: CashFlowLine) {
        func visitRevenues() {
            // visiter l'ensembles des revenus de la famille
            element.adultsRevenues.accept(self)
        }

        func visitSCI() {
            element.sciCashFlowLine.accept(self)
        }

        func visitExpenses() {
            let lifeExpenses = element.lifeExpenses
            // For every element , extract the values as a comma-separated string.
            header1.append(lifeExpenses.namedValues
                            .map({ _ in lifeExpenses.tableName.uppercased() })
                            .joined(separator: "; "))
            header2.append(lifeExpenses.namedValues
                            .map { $0.name }
                            .joined(separator: "; "))
            // total des DEPENSES
            header1.append("; ; ")
            header2.append("; \(lifeExpenses.tableName.uppercased()) TOTAL; ")
        }

        func visitTaxes() {
            // quotient familial
            header1.append("; ")
            header2.append("QUOT. FAMILIAL; ")

            element.adultTaxes.accept(self)
        }

        func visitDebts() {
            let debts = element.debtPayements
            // For every element , extract the values as a comma-separated string.
            header1.append(debts.namedValues
                            .map { _ in debts.tableName.uppercased() }
                            .joined(separator: "; "))
            header2.append(debts.namedValues
                            .map { $0.name }
                            .joined(separator: "; "))
            // total des DETTES
            header1.append("; ; ")
            header2.append("; \(debts.tableName.uppercased()) TOTAL; ")
        }

        func visitInvestements() {
            let investPayements = element.investPayements
            // For every element , extract the values as a comma-separated string.
            header1.append(investPayements.namedValues
                            .map { _ in investPayements.tableName.uppercased() }
                            .joined(separator: "; "))
            header2.append(investPayements.namedValues
                            .map { $0.name }
                            .joined(separator: "; "))
            // total des INVESTISSEMENTS
            header1.append("; ; ")
            header2.append("; \(investPayements.tableName.uppercased()) TOTAL; ")
        }

        // Année
        header1.append("; ")
        header2.append("YEAR; ")

        // Ages
        header1.append(element.ages.persons
                        .map({ _ in "Age " })
                        .joined(separator: "; "))
        header1.append(";")
        header2.append(element.ages.persons
                        .map({ $0.name })
                        .joined(separator: "; "))
        header2.append(";")

        // construire la partie Revenus du tableau
        visitRevenues()
        visitSCI()

        // somme des rentrées de trésorerie
        header1.append("RENTRÉE ; ")
        header2.append("RENTRÉE TOTAL; ")

        visitExpenses()
        visitTaxes()
        visitDebts()
        visitInvestements()

        // somme des sorties de trésoreries
        header1.append("SORTIES; ")
        header2.append("SORTIES TOTAL; ")

        // Net cashflow
        header1.append("NET CASHFLOW")
        header2.append("NET CASHFLOW")
    }

    func buildCsv(element: CashFlowArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else {
            customLog.log(level: .info, "Pas de cash flow à exporter au format CSV \(Self.self, privacy: .public)")
            return
        }

        // construire les 2 premières ligne d'entête de colonne
        element.first!.accept(self)
    }
}

extension CashFlowCsvHeaderVisitor: CustomStringConvertible {
    public var description: String {
        header1 + "\n" + header2
    }
}
