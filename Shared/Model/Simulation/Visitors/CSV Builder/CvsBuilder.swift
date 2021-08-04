//
//  CSV Visitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 09/05/2021.
//

import Foundation
import Statistics
import ModelEnvironment

// MARK: - Constructeur de fichier d'export CSV

/// The client code can run visitor operations over any set of elements without
/// figuring out their concrete classes. The accept operation directs a call to
/// the appropriate operation in the visitor object.
class CsvBuilder {

    // MARK: - Constructeur de fichier d'export CSV pour le BILAN
    
    /// Créer un fichier au format CSV contenant l'évolution du bilan annuel généré par la dernière simulation
    /// - Parameters:
    ///   - balanceSheetArray: évolution du bilan annuel généré par la dernière simulation
    ///   - mode: mode de simulation utilisé pour la dernière simulation
    /// - Returns: String au format CSV
    static func balanceSheetCSV(from balanceSheetArray : BalanceSheetArray,
                                using model            : Model,
                                withMode mode          : SimulationModeEnum) -> String {
        // construction de l'entête
        let csvHeaderBuilderVisitor = BalanceSheetCsvHeaderVisitor()
        balanceSheetArray.accept(csvHeaderBuilderVisitor)

        // construction de la table
        let csvTableBuilderVisitor = BalanceSheetCsvTableVisitor(using: model, withMode: mode)
        balanceSheetArray.accept(csvTableBuilderVisitor)

        return String(describing: csvHeaderBuilderVisitor) + "\n" + String(describing: csvTableBuilderVisitor) + "\n"
    }

    // MARK: - Constructeur de fichier d'export CSV pour le CASH FLOW

    /// Créer un fichier au format CSV contenant l'évolution du cash flow annuel généré par la dernière simulation
    /// - Parameters:
    ///   - balanceSheetArray: évolution du cash flow généré par la dernière simulation
    ///   - mode: mode de simulation utilisé pour la dernière simulation
    /// - Returns: String au format CSV
    static func cashFlowCSV(from cashFlowArray : CashFlowArray,
                            withMode mode      : SimulationModeEnum) -> String {
        // construction de l'entête
        let csvHeaderBuilderVisitor = CashFlowCsvHeaderVisitor()
        cashFlowArray.accept(csvHeaderBuilderVisitor)

        // construction de la table
        let csvTableBuilderVisitor = CashFlowCsvTableVisitor(withMode: mode)
        cashFlowArray.accept(csvTableBuilderVisitor)

        return String(describing: csvHeaderBuilderVisitor) + "\n" + String(describing: csvTableBuilderVisitor) + "\n"
    }

    // MARK: - Constructeur de fichier d'export CSV pour le MONTE-CARLO

    static func monteCarloCSV(from simulationResultTable: SimulationResultTable) -> String {
        // construction de la table
        let csvMonteCarloTableVisitor = MonteCarloCsvTableVisitor()
        simulationResultTable.accept(csvMonteCarloTableVisitor)

        return String(describing: csvMonteCarloTableVisitor)
    }
}
