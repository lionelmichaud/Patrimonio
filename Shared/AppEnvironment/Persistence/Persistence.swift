//
//  Persistence.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 13/05/2021.
//

import Foundation
import os
import Disk

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Persistence")

enum FileError: String, Error {
    case failedToSaveCashFlowCsv     = "La sauvegarde de l'historique des bilans a échoué"
    case failedToSaveBalanceSheetCsv = "La sauvegarde de l'historique des cash-flow a échoué"
    case failedToSaveMonteCarloCsv   = "La sauvegarde de l'historique des runs a échoué"
}

struct Persistence {
    
    // MARK: - Static Methods

    /// Sauvegarder le fichier historique des BILAN annuels de la simulation
    /// - Parameters:
    ///   - simulationTitle: nom de ls simulation
    ///   - csvString: String au format CSV
    static func saveToCsvPath(simulationTitle : String,
                              fileName        : String,
                              csvString       : String) throws {
        #if DEBUG
        /// sauvegarder le fichier dans le répertoire Bundle.main
        if let fileUrl = Bundle.main.url(forResource   : fileName,
                                         withExtension : nil) {
            do {
                try csvString.write(to         : fileUrl,
                                    atomically : true,
                                    encoding   : .utf8)
            } catch let error as NSError {
                customLog.log(level: .fault,
                              "Fault saving \(fileName, privacy: .public) to: \(fileUrl.path + fileName, privacy: .public)")
                fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
            }
        } else {
            customLog.log(level: .fault,
                          "Fault saving \(fileName, privacy: .public) : file not found")
        }
        #endif

        /// sauvegarder le fichier dans le répertoire: data/Containers/Data/Application/xxx/Documents/simulationTitle/csv/
        do {
            try Disk.save(Data(csvString.utf8),
                          to: .documents,
                          as: AppSettings.csvPath(simulationTitle) + fileName)
            customLog.log(level: .info,
                          "Saving \(fileName, privacy: .public) to: \(Disk.Directory.documents.pathDescription + "/" + AppSettings.csvPath(simulationTitle) + fileName, privacy: .public)")
            #if DEBUG
            print(csvString)
            #endif

        } catch let error as NSError {
            customLog.log(level: .fault,
                          "Fault saving \(fileName, privacy: .public) to: \(Disk.Directory.documents.pathDescription + "/" + AppSettings.csvPath(simulationTitle) + fileName, privacy: .public)")
            print("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
            throw error
        }
    }
}
