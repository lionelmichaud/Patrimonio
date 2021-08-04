//
//  CsvSuccessionVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 17/05/2021.
//

import Foundation
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CsvSuccessionsVisitor")

// MARK: - VISITOR: constructeur de table de SUCCESSION

/// Concrete Visitors implement several versions of the same algorithm, which
/// can work with all concrete component classes.
///
/// You can experience the biggest benefit of the Visitor pattern when using it
/// with a complex object structure, such as a Composite tree. In this case, it
/// might be helpful to store some intermediate state of the algorithm while
/// executing visitor's methods over various objects of the structure.
public class SuccessionsCsvVisitor: SuccessionCsvVisitorP {

    private var header1 = ""
    private var header2 = ""
    private var table   = ""
    private var successions: [Succession]
    private var firstSuccession = false
    private var firstHeritier   = false
    private let separator = "; "
    private let endOfLine = "\n"

    public init(successions: [Succession]) {
        self.successions = successions

        // si la table est vide alors quitter
        guard successions.isNotEmpty else {
            customLog.log(level: .info, "Pas de Succession à exporter au format CSV \(Self.self, privacy: .public)")
            return
        }

        for idx in successions.startIndex..<successions.endIndex {
            firstSuccession = (idx == successions.startIndex)
            buildCsv(element: successions[idx])
        }
    }

    public func buildCsv(element: Succession) {
        if firstSuccession {
            // construire entête
            header1.append(separator)
            header2.append("Année" + separator)
            header1.append(separator)
            header2.append("Succession" + separator)
            header1.append("Héritage" + separator)
            header2.append("de" + separator)
            header1.append("Héritage" + separator)
            header2.append("Masse successorale(k€)" + separator)
        }
        // construire table
        for idx in element.inheritances.startIndex..<element.inheritances.endIndex {
            firstHeritier = (idx == element.inheritances.startIndex)
            table.append(String(element.yearOfDeath) + separator)
            table.append(element.kind.rawValue + separator)
            table.append(element.decedentName + separator)
            table.append(String(Int(element.taxableValue/1000)) + separator)
            buildCsv(element: element.inheritances[idx])
            table.append(endOfLine)
        }
    }

    public func buildCsv(element: Inheritance) {
        if firstSuccession && firstHeritier {
            // construire entête
            header1.append("Héritier" + separator)
            header2.append("Nom" + separator)
            header1.append("Héritier" + separator)
            header2.append("% d\"héritage" + separator)
            header1.append("Héritier" + separator)
            header2.append("Brut(k€)" + separator)
            header1.append("Héritier" + separator)
            header2.append("Taxe(k€)" + separator)
            header1.append("Héritier" + separator)
            header2.append("Net(k€)" + separator)
        }
        // construire table
        table.append(element.personName + separator)
        table.append(String((element.percent * 100).percentString()) + separator)
        table.append(String(Int(element.brut/1000)) + separator)
        table.append(String(Int(-element.tax/1000)) + separator)
        table.append(String(Int(element.net/1000)) + separator)
    }
}
extension SuccessionsCsvVisitor: CustomStringConvertible {
    public var description: String {
        self.header1 + "\n" + self.header2 + "\n" + self.table
    }
}
