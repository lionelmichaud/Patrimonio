//
//  CSV Visitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 09/05/2021.
//

import Foundation
import Statistics
import ModelEnvironment
import Succession
import Persistence
import BalanceSheet
import CashFlow
import SocialAccounts

// MARK: - Constructeur de fichier d'export CSV

/// The client code can run visitor operations over any set of elements without
/// figuring out their concrete classes. The accept operation directs a call to
/// the appropriate operation in the visitor object.
struct CsvBuilder {
    
    // MARK: - Constructeur de fichier d'export CSV pour une SIMULATION
    
    /// Générer les String au format CSV à partir des résultats de la dernière simulation réalisée
    ///
    /// - un fichier pour le Cash Flow
    /// - un fichier pour le Bilan
    /// - un fichier pour les Successions
    /// - un fichier pour le tableau de résultat de Monté-Carlo
    ///
    /// - Parameters:
    ///   - simulation: la simulation à convertir
    ///   - model: modèle à utiliser
    /// - Returns: dictionnaire [Nom de fichier : CSV string]
    static func simulationResultsCSV(from simulation : Simulation,
                                     using model     : Model) -> [String:String] {
        /// - un fichier pour le Cash Flow
        /// - un fichier pour le Bilan
        /// - un fichier pour les Successions
        var dicoOfCsv =
            CsvBuilder.socialAccountsCSVs(from     : simulation.socialAccounts,
                                          using    : model,
                                          withMode : simulation.mode)
        
        /// - un fichier pour le tableau de résultat de Monté-Carlo
        if simulation.mode == .deterministic {
            dicoOfCsv[FileNameCst.kMonteCarloCSVFileName] =
                CsvBuilder.monteCarloCSV(from: [simulation.currentRunResults])
        } else {
            dicoOfCsv[FileNameCst.kMonteCarloCSVFileName] =
                CsvBuilder.monteCarloCSV(from: simulation.monteCarloResultTable)
        }
        
        return dicoOfCsv
    }
    
    // MARK: - Constructeur de fichier d'export CSV pour les SOCIAL-ACCOUNTS
    
    /// Générer les String au format CSV à partir des résultats de la dernière simulation réalisée
    ///
    /// - un fichier pour le Cash Flow
    /// - un fichier pour le Bilan
    /// - un fichier pour les Successions
    ///
    /// - Parameters:
    ///   - socialAccounts: les comptes sociaux
    ///   - mode: mode de simulation utilisé lors de la dernière simulation
    ///   - model: modèle à utiliser
    /// - Returns: dictionnaire [Nom de fichier : CSV string]
    fileprivate static func socialAccountsCSVs(from socialAccounts: SocialAccounts,
                                               using model  : Model,
                                               withMode mode: SimulationModeEnum) -> [String:String] {
        var dico = [String:String]()
        // construction du tableau de bilans annnuels au format CSV
        dico[FileNameCst.kBalanceSheetCSVFileName] =
            CsvBuilder.balanceSheetCSV(from     : socialAccounts.balanceArray,
                                       using    : model,
                                       withMode : mode)
        // construction du tableau de cash flow annnuels au format CSV
        dico[FileNameCst.kCashFlowCSVFileName] =
            CsvBuilder.cashFlowCSV(from     : socialAccounts.cashFlowArray,
                                   withMode : mode)
        // construction du tableau des successions
        dico[FileNameCst.kSuccessionsCSVFileName]  =
            String(describing: SuccessionsCsvVisitor(successions: socialAccounts.legalSuccessions + socialAccounts.lifeInsSuccessions))
        
        return dico
    }
    
    // MARK: - Constructeur de fichier d'export CSV pour le BILAN
    
    /// Créer un fichier au format CSV contenant l'évolution du bilan annuel généré par la dernière simulation
    /// - Parameters:
    ///   - balanceSheetArray: évolution du bilan annuel généré par la dernière simulation
    ///   - model: modèle à utiliser
    ///   - mode: mode de simulation utilisé pour la dernière simulation
    /// - Returns: String au format CSV
    fileprivate static func balanceSheetCSV(from balanceSheetArray : BalanceSheetArray,
                                            using model            : Model,
                                            withMode mode          : SimulationModeEnum) -> String {
        // construction de l'entête
        let csvHeaderBuilderVisitor = BalanceSheetCsvHeaderVisitor()
        balanceSheetArray.accept(csvHeaderBuilderVisitor)
        
        // construction de la table
        let csvTableBuilderVisitor = BalanceSheetCsvTableVisitor(using    : model,
                                                                 withMode : mode)
        balanceSheetArray.accept(csvTableBuilderVisitor)
        
        return String(describing: csvHeaderBuilderVisitor) + "\n" + String(describing: csvTableBuilderVisitor) + "\n"
    }
    
    // MARK: - Constructeur de fichier d'export CSV pour le CASH FLOW
    
    /// Créer un fichier au format CSV contenant l'évolution du cash flow annuel généré par la dernière simulation
    /// - Parameters:
    ///   - balanceSheetArray: évolution du cash flow généré par la dernière simulation
    ///   - mode: mode de simulation utilisé pour la dernière simulation
    /// - Returns: String au format CSV
    fileprivate static func cashFlowCSV(from cashFlowArray : CashFlowArray,
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
