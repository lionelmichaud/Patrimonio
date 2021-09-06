//
//  SimulationResultTable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 28/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import EconomyModel
import SocioEconomyModel
import Files
import Persistence
import FamilyModel

// MARK: - Runs results

enum RunResult: String, Codable {
    case allObjectivesReached
    case someObjectiveMissed
    case someObjectiveUndefined
}

enum RunFilterEnum: String, Codable {
    case all
    case someBad
    case somUnknown
}

// MARK: - VISITOR de Propriétés aléatoires d'un Adult

extension DictionaryOfAdultRandomProperties: MonteCarloVisitableP {
    func accept(_ visitor: MonteCarloVisitorP) {
        visitor.visit(element: self)
    }
}

// MARK: - Synthèse d'un Run de Simulation

struct SimulationResultLine: Hashable {
    var runNumber                         : Int = 1
    var dicoOfAdultsRandomProperties      = DictionaryOfAdultRandomProperties()
    var dicoOfEconomyRandomVariables      = Economy.DictionaryOfRandomVariable()
    var dicoOfSocioEconomyRandomVariables = SocioEconomy.DictionaryOfRandomVariable()
    var dicoOfKpiResults                  = KpiResultsDictionary()
}
extension SimulationResultLine: MonteCarloVisitableP {
    func accept(_ visitor: MonteCarloVisitorP) {
        visitor.visit(element: self)
    }
}

// MARK: - Tableau de Synthèse d'un Run de Simulation

enum KpiSortCriteriaEnum: String, Codable {
    case byRunNumber
    case byKpi1
    case byKpi2
    case byKpi3
}

typealias SimulationResultTable = [SimulationResultLine]

extension SimulationResultTable {
    func filtered(with filter: RunFilterEnum = .all) -> SimulationResultTable {
        switch filter {
            case .all:
                return self
            case .someBad:
                return self.filter { $0.dicoOfKpiResults.runResult() == .someObjectiveMissed }
            case .somUnknown:
                return self.filter { $0.dicoOfKpiResults.runResult() == .someObjectiveUndefined }
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    func sorted(by criteria    : KpiSortCriteriaEnum,
                with sortOrder : SortingOrder = .ascending) -> SimulationResultTable {
        switch criteria {
            case .byRunNumber:
                return self.sorted(by: {
                    switch sortOrder {
                        case .ascending:
                            return $1.runNumber > $0.runNumber
                        case .descending:
                            return $1.runNumber < $0.runNumber
                    }
                })
            case .byKpi1:
                return self.sorted(by: {
                    switch sortOrder {
                        case .ascending:
                            return ($1.dicoOfKpiResults[.minimumAdultsAssetExcludinRealEstates]?.value ?? 0) > ($0.dicoOfKpiResults[.minimumAdultsAssetExcludinRealEstates]?.value ?? 0)
                        case .descending:
                            return ($1.dicoOfKpiResults[.minimumAdultsAssetExcludinRealEstates]?.value ?? 0) < ($0.dicoOfKpiResults[.minimumAdultsAssetExcludinRealEstates]?.value ?? 0)
                    }
                })
            case .byKpi2:
                return self.sorted(by: {
                    switch sortOrder {
                        case .ascending:
                            return ($1.dicoOfKpiResults[.assetAt1stDeath]?.value ?? 0) > ($0.dicoOfKpiResults[.assetAt1stDeath]?.value ?? 0)
                        case .descending:
                            return ($1.dicoOfKpiResults[.assetAt1stDeath]?.value ?? 0) < ($0.dicoOfKpiResults[.assetAt1stDeath]?.value ?? 0)
                    }
                })
            case .byKpi3:
                return self.sorted(by: {
                    switch sortOrder {
                        case .ascending:
                            return ($1.dicoOfKpiResults[.assetAt2ndtDeath]?.value ?? 0) > ($0.dicoOfKpiResults[.assetAt2ndtDeath]?.value ?? 0)
                        case .descending:
                            return ($1.dicoOfKpiResults[.assetAt2ndtDeath]?.value ?? 0) < ($0.dicoOfKpiResults[.assetAt2ndtDeath]?.value ?? 0)
                    }
                })
        }
    }

    func save(to folder       : Folder,
              simulationTitle : String) throws {
        let csvString = CsvBuilder.monteCarloCSV(from: self)
        do {
            try PersistenceManager.saveToCsvPath(to              : folder,
                                                 fileName        : FileNameCst.kMonteCarloCSVFileName,
                                                 simulationTitle : simulationTitle,
                                                 csvString       : csvString)
        } catch {
            throw FileError.failedToSaveMonteCarloCsv
        }
    }
}

// MARK: - VISITOR de Tableau de Synthèse d'un Run de Simulation

extension SimulationResultTable: MonteCarloVisitableP {
    func accept(_ visitor: MonteCarloVisitorP) {
        visitor.visit(element: self)
    }
}
