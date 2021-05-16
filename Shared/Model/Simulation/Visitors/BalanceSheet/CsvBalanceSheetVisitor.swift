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

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CsvBalanceSheetTableVisitor")

// MARK: - VISITOR: constructeur de table de BILAN

/// Concrete Visitors implement several versions of the same algorithm, which
/// can work with all concrete component classes.
///
/// You can experience the biggest benefit of the Visitor pattern when using it
/// with a complex object structure, such as a Composite tree. In this case, it
/// might be helpful to store some intermediate state of the algorithm while
/// executing visitor's methods over various objects of the structure.
class CsvBalanceSheetTableVisitor: BalanceSheetCsvVisitorP {

    private var table  = ""
    private let mode: SimulationModeEnum

    internal init(withMode mode: SimulationModeEnum) {
        self.mode = mode
    }

    func buildCsv(element: ValuedLiabilities) {
        LiabilitiesCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let namedValueTable = element[category] else { return }

            let namedValues = namedValueTable.namedValues
            table.append(namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: "; "))
            // valeure cumulée de la catégorie
            table.append("; \(namedValueTable.total.roundedString);")
        }
    }

    func buildCsv(element: ValuedAssets) {
        AssetsCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let namedValueTable = element[category] else { return }

            let namedValues = namedValueTable.namedValues
            table.append(namedValues
                            .map { $0.value.roundedString }
                            .joined(separator: "; "))
            // valeure cumulée de la catégorie
            table.append("; \(namedValueTable.total.roundedString); ")
        }
    }

    func buildCsv(element: BalanceSheetLine) {
        func visitAssets() {
            // visiter l'ensembles des actifs de la famille
            guard let valuedAssets = element.assets[AppSettings.shared.allPersonsLabel] else { return }
            valuedAssets.accept(self)
            // total des ACTIFS
            table.append("\(valuedAssets.total.roundedString); ")
        }

        func visitLiabilities() {
            // visiter l'ensembles des actifs de la famille
            guard let valuedLiabilities = element.liabilities[AppSettings.shared.allPersonsLabel] else { return }
            valuedLiabilities.accept(self)
            // total des PASSIFS
            table.append("\(valuedLiabilities.total.roundedString); ")
        }

        table.append("\(element.year); ")
        table.append("\(Economy.model.randomizers.inflation.value(withMode: mode).percentString(digit: 1)); ")
        table.append("\(Economy.model.rates(in: element.year, withMode: mode, simulateVolatility: UserSettings.shared.simulateVolatility).securedRate.percentString(digit: 1)); ")
        table.append("\(Economy.model.rates(in: element.year, withMode: mode, simulateVolatility: UserSettings.shared.simulateVolatility).stockRate.percentString(digit: 1)); ")

        // actifs
        visitAssets()

        // passifs
        visitLiabilities()

        // net
        table.append("\(element.netAssets.roundedString)")
    }

    func buildCsv(element: BalanceSheetArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else {
            customLog.log(level: .info, "Pas de bilan à exporter au format CSV \(Self.self, privacy: .public)")
            return
        }

        // construire le tableau de valeurs: une ligne par année
        for idx in 0..<element.endIndex {
            element[idx].accept(self)
            table.append("\n")
        }
    }
}

// MARK: - VISITOR: constructeur d'entête de table de BILAN

extension CsvBalanceSheetTableVisitor: CustomStringConvertible {
    public var description: String {
        return table
    }
}

class CsvBalanceSheetHeaderVisitor: BalanceSheetCsvVisitorP {

    private var header0  = ""
    private var header1  = ""
    private var header2  = ""

    func buildCsv(element: ValuedAssets) {
        AssetsCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let namedValueTable = element[category] else { return }

            let namedValues = namedValueTable.namedValues
            header0.append(namedValues
                            .map { _ in "ACTIF" }
                            .joined(separator: "; "))
            header1.append(namedValues
                            .map { _ in namedValueTable.tableName.uppercased() }
                            .joined(separator: "; "))
            header2.append(namedValues
                            .map { $0.name }
                            .joined(separator: "; "))
            // valeure cumulée de la catégorie
            header0.append("; ACTIF; ")
            header1.append("; ; ")
            header2.append("; \(namedValueTable.tableName.uppercased()) TOTAL; ")
        }
    }

    func buildCsv(element: ValuedLiabilities) {
        LiabilitiesCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let namedValueTable = element[category] else { return }

            let namedValues = namedValueTable.namedValues
            header0.append(namedValues
                            .map { _ in "PASSIF" }
                            .joined(separator: "; "))
            header1.append(namedValues
                            .map { _ in namedValueTable.tableName.uppercased() }
                            .joined(separator: "; "))
            header2.append(namedValues
                            .map { $0.name }
                            .joined(separator: "; "))
            // valeure cumulée de la catégorie
            header0.append("; PASSIF; ")
            header1.append("; ; ")
            header2.append("; \(namedValueTable.tableName.uppercased()) TOTAL; ")
        }
    }

    func buildCsv(element: BalanceSheetLine) {
        func visitAssets() {
            // visiter l'ensembles des actifs de la famille
            guard let valuedAssets = element.assets[AppSettings.shared.allPersonsLabel] else { return }
            valuedAssets.accept(self)
            // total des ACTIFS
            header0.append("ACTIF; ")
            header1.append("; ")
            header2.append("ACTIF TOTAL; ")
        }

        func visitLiabilities() {
            // visiter l'ensembles des actifs de la famille
            guard let valuedLiabilities = element.liabilities[AppSettings.shared.allPersonsLabel] else { return }
            valuedLiabilities.accept(self)
            // total des PASSIFS
            header0.append("PASSIF; ")
            header1.append("; ")
            header2.append("PASSIF TOTAL; ")
        }

        header0.append("; ; ; ; ")
        header1.append("; ; ; ; ")
        header2.append("YEAR; ")
        header2.append("Inflation; ")
        header2.append("Taux Oblig; ")
        header2.append("Taux Action; ")

        // actifs
        visitAssets()

        // passifs
        visitLiabilities()

        // net
        header0.append("BILAN")
        header2.append("NET")
    }

    func buildCsv(element: BalanceSheetArray) {
        // si la table est vide alors quitter
        guard element.isNotEmpty else {
            customLog.log(level: .info, "Pas de bilan à exporter au format CSV \(Self.self, privacy: .public)")
            return
        }

        // construire les 2 premières ligne d'entête de colonne
        element.first!.accept(self)
    }
}

extension CsvBalanceSheetHeaderVisitor: CustomStringConvertible {
    public var description: String {
        header0 + "\n" + header1 + "\n" + header2
    }
}
