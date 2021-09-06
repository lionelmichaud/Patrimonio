//
//  KpiResult.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 06/09/2021.
//

import Foundation

// MARK: - KPI results

struct KpiResult: Hashable, Codable {
    var value              : Double
    var objectiveIsReached : Bool
}

typealias KpiResultsDictionary = [KpiEnum: KpiResult]
extension KpiResultsDictionary {
    func runResult() -> RunResult {
        for kpi in KpiEnum.allCases {
            if let objectiveIsReached = self[kpi]?.objectiveIsReached {
                if !objectiveIsReached {
                    // un résultat est défini avec un objectif non atteint
                    return .someObjectiveMissed
                }
            } else {
                // un résultat non défini
                return .someObjectiveUndefined
            }
        }
        // tous les résultats sont définis et les objectifs sont toujours atteints
        return .allObjectivesReached
    }
}
