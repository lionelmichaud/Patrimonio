//
//  CsvMonteCarloTableVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 13/05/2021.
//

import Foundation
import os
import EconomyModel
import SocioEconomyModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CsvMonteCarloTableVisitor")

// MARK: - VISITOR: constructeur de table de MONTE-CARLO RESULT

/// Concrete Visitors implement several versions of the same algorithm, which
/// can work with all concrete component classes.
///
/// You can experience the biggest benefit of the Visitor pattern when using it
/// with a complex object structure, such as a Composite tree. In this case, it
/// might be helpful to store some intermediate state of the algorithm while
/// executing visitor's methods over various objects of the structure.
class MonteCarloCsvTableVisitor: MonteCarloVisitorP {
    private let separator = "; "
    private let lineBreak = "\n"
    private var header  = ""
    private var table  = ""
    private var line = ""

    func visit(element: DictionaryOfAdultRandomProperties) {
        for name in element.keys.sorted() {
            line += String(element[name]!.ageOfDeath) + separator
            line += String(element[name]!.nbOfYearOfDependency) + separator
        }
    }

    func visit(element: SimulationResultLine) {
        // numéro du run
        line = String(element.runNumber) + separator

        // propriétés aléatoires des adultes
        element.dicoOfAdultsRandomProperties.accept(self)

        // valeurs aléatoires de conditions économiques
        for variableEnum in Economy.RandomVariable.allCases {
            line += (element.dicoOfEconomyRandomVariables[variableEnum]?.percentString(digit: 1) ?? "") + separator
        }
        // valeurs aléatoires de conditions socio-économiques
        for variableEnum in SocioEconomy.RandomVariable.allCases {
            switch variableEnum {
                case .nbTrimTauxPlein:
                    line += element.dicoOfSocioEconomyRandomVariables[variableEnum]!.roundedString + separator

                default:
                    line += element.dicoOfSocioEconomyRandomVariables[variableEnum]!.percentString(digit: 1) + separator
            }
        }
        // valeurs résultantes des KPIs
        for kpiEnum in SimulationKPIEnum.allCases {
            if let kpiResult = element.dicoOfKpiResults[kpiEnum] {
                line += kpiResult.value.roundedString + separator
            } else {
                line += "indéfini" + separator
            }
        }
        table.append(line)
    }

    func visit(element: SimulationResultTable) {
        func buildHeader() -> String {
            var header = "Run" + separator
            // propriétés aléatoires des adultes
            for name in element.first!.dicoOfAdultsRandomProperties.keys.sorted() {
                header += "Durée de Vie " + name + separator
                header += "Dépendance " + name + separator
            }
            // valeurs aléatoires de conditions économiques
            for variableEnum in Economy.RandomVariable.allCases {
                header += variableEnum.pickerString + separator
            }
            // valeurs aléatoires de conditions socio-économiques
            for variableEnum in SocioEconomy.RandomVariable.allCases {
                header += variableEnum.pickerString + separator
            }
            // valeurs résultantes des KPIs
            for variableEnum in SimulationKPIEnum.allCases {
                header += variableEnum.pickerString + separator
            }
            return header
        }

        // si la table est vide alors quitter
        guard element.isNotEmpty else {
            customLog.log(level: .info, "Pas de Monté-Carlo à exporter au format CSV \(Self.self, privacy: .public)")
            return
        }

        header = buildHeader()

        // construire le tableau de valeurs: une ligne par année
        for idx in element.startIndex..<element.endIndex {
            element[idx].accept(self)
            table.append(lineBreak)
        }
    }
}

extension MonteCarloCsvTableVisitor: CustomStringConvertible {
    public var description: String {
        header + lineBreak + table
    }
}
