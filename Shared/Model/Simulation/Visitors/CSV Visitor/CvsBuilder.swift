//
//  CSV Visitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 09/05/2021.
//

import Foundation
import Statistics

// MARK: - Constructeur de fichier d'export CSV

/// The client code can run visitor operations over any set of elements without
/// figuring out their concrete classes. The accept operation directs a call to
/// the appropriate operation in the visitor object.
class CsvBuilder {
    // MARK: - Constructeur de fichier d'export CSV pour le BILAN
    static func visit(components   : BalanceSheetArray,
                      with visitor : BalanceSheetVisitor) {
        components.accept(visitor)
        print(visitor)
    }
    static func visit(components   : BalanceSheetArray,
                      with visitor : CsvHeaderBuilderVisitor) {
        components.accept(visitor)
        print(visitor)
    }

    /// Créer un fichier au format CSV contenant l'évolution du bilan annuel généré par la dernière simulation
    /// - Parameters:
    ///   - balanceSheetArray: évolution du bilan annuel généré par la dernière simulation
    ///   - mode: mode de simulation utilisé pour la dernière simulation
    /// - Returns: String au format CSV
    static func balanceSheetCSV(from balanceSheetArray : BalanceSheetArray,
                                withMode mode          : SimulationModeEnum) -> String {
        // construction de l'entête
        let csvHeaderBuilderVisitor = CsvHeaderBuilderVisitor()
        visit(components : balanceSheetArray,
              with       : csvHeaderBuilderVisitor)

        // construction de la table
        let csvTableBuilderVisitor = CsvTableBuilderVisitor(withMode: mode)
        visit(components : balanceSheetArray,
              with       : csvTableBuilderVisitor)

        return String(describing: csvHeaderBuilderVisitor) + "\n" + String(describing: csvTableBuilderVisitor)
    }

    // MARK: - Constructeur de fichier d'export CSV pour le CASH FLOW
    static func visit(components   : CashFlowArray,
                      with visitor : BalanceSheetVisitor) {
        components.accept(visitor)
        print(visitor)
    }
    static func visit(components   : CashFlowArray,
                      with visitor : CsvHeaderBuilderVisitor) {
        components.accept(visitor)
        print(visitor)
    }

    /// Créer un fichier au format CSV contenant l'évolution du cash flow annuel généré par la dernière simulation
    /// - Parameters:
    ///   - balanceSheetArray: évolution du cash flow généré par la dernière simulation
    ///   - mode: mode de simulation utilisé pour la dernière simulation
    /// - Returns: String au format CSV
    static func cashFlowCSV(from cashFlowArray : CashFlowArray,
                            withMode mode      : SimulationModeEnum) -> String {
        // construction de l'entête
        let csvHeaderBuilderVisitor = CsvHeaderBuilderVisitor()
        visit(components: cashFlowArray, with: csvHeaderBuilderVisitor)

        // construction de la table
        let csvTableBuilderVisitor = CsvTableBuilderVisitor(withMode: mode)
        visit(components: cashFlowArray, with: csvTableBuilderVisitor)

        return String(describing: csvHeaderBuilderVisitor) + "\n" + String(describing: csvTableBuilderVisitor)
    }
}
