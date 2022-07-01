//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 21/12/2021.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CashFlowCsvHeaderVisitor")

// MARK: - VISITOR: constructeur d'entête de table de CASH FLOW

public final class CashFlowCsvHeaderVisitor: CashFlowCsvVisitorP {
    
    private var header1  = ""
    private var header2  = ""
    private var header3  = ""
    private var header4  = ""
    
    public init(header1: String = "",
                header2: String = "",
                header3: String = "",
                header4: String = "") {
        self.header1 = header1
        self.header2 = header2
        self.header3 = header3
        self.header4 = header4
    }
    
    public func buildCsv(element: SciCashFlowLine.Revenues) {
        let sciDividends = element.scpiDividends
        // For every element , extract the values as a comma-separated string.
        header1.append(sciDividends.namedValues
                        .map { _ in "RENTRÉE" }
                        .joined(separator: ";"))
        header2.append(sciDividends.namedValues
                        .map { _ in "RENTRÉE SCI" }
                        .joined(separator: ";"))
        header3.append(sciDividends.namedValues
                        .map { _ in sciDividends.tableName.uppercased() }
                        .joined(separator: ";"))
        header4.append(sciDividends.namedValues
                        .map { $0.name }
                        .joined(separator: ";"))
        // total des DIVIDENDES
        header1.append(";>INFO;")
        header2.append(";TOTAL;")
        header3.append(";SOUS-TOTAL RENTRÉES;")
        header4.append(";\(sciDividends.tableName.uppercased()) TOTAL;")
        
        let sciSales = element.scpiSale
        // For every element , extract the values as a comma-separated string.
        header1.append(sciDividends.namedValues
                        .map { _ in "RENTRÉE" }
                        .joined(separator: ";"))
        header2.append(sciDividends.namedValues
                        .map { _ in "RENTRÉE SCI" }
                        .joined(separator: ";"))
        header3.append(sciSales.namedValues
                        .map { _ in sciSales.tableName.uppercased() }
                        .joined(separator: ";"))
        header4.append(sciSales.namedValues
                        .map { $0.name }
                        .joined(separator: ";"))
        // total des VENTES
        header1.append(";>INFO;")
        header2.append(";TOTAL;")
        header3.append(";SOUS-TOTAL RENTRÉES;")
        header4.append(";\(sciSales.tableName.uppercased()) TOTAL;")
    }
    
    public func buildCsv(element: SciCashFlowLine) {
        element.revenues.accept(self)
        
        header1.append("RENTRÉE;")
        header2.append("RENTRÉE SCI;")
        header3.append("SCI-IS;")
        header4.append("IS;")
        
        header1.append(">INFO;")
        header2.append("TOTAL;")
        header3.append("SOUS-TOTAL RENTRÉES;")
        header4.append("REVENU SCI NET TOTAL;")
    }
    
    public func buildCsv(element: ValuedRevenues) {
        // pour chaque catégorie
        RevenueCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let revenuesInCategory = element[category] else { return }
            
            let namedValues = revenuesInCategory.credits.namedValues
            header1.append(namedValues
                            .map { _ in "RENTRÉE" }
                            .joined(separator: ";"))
            header2.append(namedValues
                            .map { _ in "RENTRÉE PARENTS" }
                            .joined(separator: ";"))
            header3.append(namedValues
                            .map { _ in category.rawValue.uppercased() }
                            .joined(separator: ";"))
            header4.append(namedValues
                            .map { $0.name }
                            .joined(separator: ";"))
            // valeure cumulée de la catégorie
            header1.append(";>INFO;")
            header2.append(";TOTAL;")
            header3.append(";SOUS-TOTAL RENTRÉES;")
            header4.append(";\(revenuesInCategory.credits.tableName.uppercased()) TOTAL;")
        }
        // total des REVENUS
        header1.append(">INFO;")
        header2.append("TOTAL;")
        header3.append("SOUS-TOTAL RENTRÉES;")
        header4.append("REVENU PARENTS TOTAL;")
    }
    
    public func buildCsv(element: ValuedTaxes) {
        // For every element , extract the values as a comma-separated string.
        TaxeCategory.allCases.forEach { category in
            // seulement ceux de la catégorie
            guard let taxesInCategory = element[category] else { return }
            
            let namedValues = taxesInCategory.namedValues
            header1.append(namedValues
                            .map({ _ in "SORTIES" })
                            .joined(separator: ";"))
            header2.append(namedValues
                            .map({ _ in "TAXES PARENTS" })
                            .joined(separator: ";"))
            header3.append(namedValues
                            .map({ _ in category.rawValue.uppercased() })
                            .joined(separator: ";"))
            header4.append(namedValues
                            .map { $0.name }
                            .joined(separator: ";"))
            // valeure cumulée de la catégorie
            header1.append(";>INFO;")
            header2.append(";TOTAL;")
            header3.append(";SOUS-TOTAL SORTIES;")
            header4.append(";\(taxesInCategory.tableName.uppercased()) TOTAL;")
        }
        // total des TAXES
        header1.append(">INFO;")
        header2.append("TOTAL;")
        header3.append("SOUS-TOTAL SORTIES;")
        header4.append("IMPOTS & TAXES TOTAL;")
    }
    
    public func buildCsv(element: CashFlowLine) {
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
                            .map({ _ in "SORTIES" })
                            .joined(separator: ";"))
            header2.append(lifeExpenses.namedValues
                            .map({ _ in "DÉPENSES PARENTS" })
                            .joined(separator: ";"))
            header3.append(lifeExpenses.namedValues
                            .map({ _ in lifeExpenses.tableName.uppercased() })
                            .joined(separator: ";"))
            header4.append(lifeExpenses.namedValues
                            .map { $0.name }
                            .joined(separator: ";"))
            // total des DEPENSES
            header1.append(";>INFO;")
            header2.append(";TOTAL;")
            header3.append(";SOUS-TOTAL SORTIES;")
            header4.append(";\(lifeExpenses.tableName.uppercased()) TOTAL;")
        }
        
        func visitTaxes() {
            // quotient familial
            header1.append(">INFO;")
            header2.append("DATA;")
            header3.append("FISCAL;")
            header4.append("QUOT. FAMILIAL;")
            
            element.adultTaxes.accept(self)
        }
        
        func visitDebts() {
            let debts = element.debtPayements
            // For every element , extract the values as a comma-separated string.
            header1.append(debts.namedValues
                            .map { _ in "SORTIES" }
                            .joined(separator: ";"))
            header2.append(debts.namedValues
                            .map { _ in debts.tableName.uppercased() }
                            .joined(separator: ";"))
            header3.append(debts.namedValues
                            .map { _ in debts.tableName.uppercased() }
                            .joined(separator: ";"))
            header4.append(debts.namedValues
                            .map { $0.name }
                            .joined(separator: ";"))
            // total des DETTES
            header1.append(";>INFO;")
            header2.append(";TOTAL;")
            header3.append(";SOUS-TOTAL SORTIES;")
            header4.append(";\(debts.tableName.uppercased()) TOTAL;")
        }
        
        func visitInvestements() {
            let investPayements = element.investPayements
            // For every element , extract the values as a comma-separated string.
            header1.append(investPayements.namedValues
                            .map { _ in "SORTIES" }
                            .joined(separator: ";"))
            header2.append(investPayements.namedValues
                            .map { _ in investPayements.tableName.uppercased() }
                            .joined(separator: ";"))
            header3.append(investPayements.namedValues
                            .map { _ in investPayements.tableName.uppercased() }
                            .joined(separator: ";"))
            header4.append(investPayements.namedValues
                            .map { $0.name }
                            .joined(separator: ";"))
            // total des INVESTISSEMENTS
            header1.append(";>INFO;")
            header2.append(";TOTAL;")
            header3.append(";SOUS-TOTAL SORTIES;")
            header4.append(";\(investPayements.tableName.uppercased()) TOTAL;")
        }
        
        // Année
        header1.append(";")
        header2.append(";")
        header3.append(";")
        header4.append("YEAR;")
        
        // Ages
        header1.append(element.ages.persons
                        .map({ _ in "FAMILLE" })
                        .joined(separator: ";"))
        header1.append(";")
        header2.append(element.ages.persons
                        .map({ _ in "MEMBRE" })
                        .joined(separator: ";"))
        header2.append(";")
        header3.append(element.ages.persons
                        .map({ _ in "Age" })
                        .joined(separator: ";"))
        header3.append(";")
        header4.append(element.ages.persons
                        .map({ $0.name })
                        .joined(separator: ";"))
        header4.append(";")
        
        // construire la partie Revenus du tableau
        visitRevenues()
        visitSCI()
        
        // somme des rentrées de trésorerie
        header1.append(">INFO;")
        header2.append("TOTAL;")
        header3.append("TOTAL;")
        header4.append("RENTRÉE TOTAL;")
        
        visitExpenses()
        visitTaxes()
        visitDebts()
        visitInvestements()
        
        // somme des sorties de trésoreries
        header1.append(">INFO;")
        header2.append("TOTAL;")
        header3.append("TOTAL;")
        header4.append("SORTIES TOTAL;")
        
        // Net cashflow
        header1.append("NET CASHFLOW")
        header2.append("NET CASHFLOW")
        header3.append("NET CASHFLOW")
        header4.append("NET CASHFLOW")
    }
    
    public func buildCsv(element: CashFlowArray) {
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
        header1 + "\n" + header2 + "\n" + header3 + "\n" + header4
    }
}
