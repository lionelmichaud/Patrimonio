import Foundation
import Statistics
import EconomyModel
import SocioEconomyModel
import Disk
import os

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CsvBuilder")

// MARK: - BalanceSheetArray: Table des Bilans annuels

typealias BalanceSheetArray = [BalanceSheetLine]

// MARK: - BalanceSheetArray extension for CSV export

extension BalanceSheetArray: BalanceSheetVisitable {
     func accept(_ visitor: BalanceSheetVisitor) {
        visitor.visit(element: self)
    }
}

extension BalanceSheetArray {
    func storeTableCSV(simulationTitle: String,
                       withMode mode  : SimulationModeEnum) {
        var heading = String()
        var rows    = [String]()
        
        func buildAssetsTableCSV(firstLine: BalanceSheetLine) {
            // pour chaque catégorie
            AssetsCategory.allCases.forEach { category in
                // heading
                //heading += firstLine.assets[AppSettings.shared.allPersonsLabel]!.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                //rows = zip(rows,
                //           self.map { "\($0.assets[AppSettings.shared.allPersonsLabel]!.valuesCSV(category)!); " })
                //    .map(+)
            }
            // total
            // heading
            heading += "ACTIF TOTAL; "
            // valeurs
            let rowsTotal = self.map { "\($0.assets[AppSettings.shared.allPersonsLabel]!.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildLiabilitiesTableCSV(firstline: BalanceSheetLine) {
            // pour chaque catégorie
            LiabilitiesCategory.allCases.forEach { category in
                // heading
                //heading += firstLine.liabilities[AppSettings.shared.allPersonsLabel]!.headersCSV(category)! + "; "
                // valeurs
                // values: For every element , extract the values as a comma-separated string.
                //rows = zip(rows,
                //           self.map { "\($0.liabilities[AppSettings.shared.allPersonsLabel]!.valuesCSV(category)!); " })
                //    .map(+)
            }
            // total
            // heading
            heading += "PASSIF TOTAL; "
            // valeurs
            let rowsTotal = self.map { "\($0.liabilities[AppSettings.shared.allPersonsLabel]!.total.roundedString); " }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        func buildNetTableCSV(firstline: BalanceSheetLine) {
            // heading
            heading += "ACTIF NET"
            // valeurs
            let rowsTotal = self.map { "\($0.netAssets.roundedString)" }
            rows = zip(rows, rowsTotal).map(+)
        }
        
        // si la table est vide alors quitter
        guard !self.isEmpty else {
            customLog.log(level: .info, "Pas de bilan à exporter au format CSV \(Self.self, privacy: .public)")
            return
        }
        
        let firstLine = self.first!
        
        // ligne de titre du tableau: utiliser la première ligne de la table de bilan
        heading = "YEAR; " // + self.first!.headerCSV
        rows = self.map { "\($0.year); " }
        
        // inflation
        // heading
        heading += "Inflation; "
        // valeurs
        let rowsInflationRate = self.map { _ in "\(Economy.model.randomizers.inflation.value(withMode: mode).percentString(digit: 1)); " }
        rows = zip(rows, rowsInflationRate).map(+)
        
        // taux des obligations
        // heading
        heading += "Taux Oblig; "
        // valeurs
        let rowsSecuredRate = self.map {
            "\(Economy.model.rates(in: $0.year, withMode: mode, simulateVolatility: UserSettings.shared.simulateVolatility).securedRate.percentString(digit: 1)); "
        }
        rows = zip(rows, rowsSecuredRate).map(+)
        
        // taux des actions
        // heading
        heading += "Taux Action; "
        // valeurs
        let rowsStockRate = self.map {
            "\(Economy.model.rates(in: $0.year, withMode: mode, simulateVolatility: UserSettings.shared.simulateVolatility).stockRate.percentString(digit: 1)); "
        }
        rows = zip(rows, rowsStockRate).map(+)
        
        // construire la partie Actifs du tableau
        buildAssetsTableCSV(firstLine: firstLine)
        
        // construire la partie Passifs du tableau
        buildLiabilitiesTableCSV(firstline: firstLine)
        
        // ajoute le total Actif Net au bout
        buildNetTableCSV(firstline: firstLine)
        
        // Turn all of the rows into one big string
        let csvString = heading + "\n" + rows.joined(separator: "\n")
        
        //        print(SocialAccounts.balanceSheetFileUrl ?? "nil")
        //        print(csvString)
        
        #if DEBUG
        // sauvegarder le fichier dans le répertoire Bundle/csv
        do {
            try csvString.write(to: SocialAccounts.balanceSheetFileUrl!, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file: \(error)")
        }
        #endif
        
        // sauvegarder le fichier dans le répertoire Data/Documents/csv
        let fileName = "BalanceSheet.csv"
        do {
            try Disk.save(Data(csvString.utf8),
                          to: .documents,
                          as: AppSettings.csvPath(simulationTitle) + fileName)
            #if DEBUG
            Swift.print("saving \(fileName) to file: ", AppSettings.csvPath(simulationTitle) + fileName)
            print(csvString)
            #endif
            
        } catch let error as NSError {
            fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
        }
    }
}
