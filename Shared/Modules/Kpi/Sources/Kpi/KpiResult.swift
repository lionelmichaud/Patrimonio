//
//  KpiResult.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 06/09/2021.
//

import Foundation

// MARK: - KPI results

public struct KpiResult: Hashable, Codable {
    public var value              : Double
    public var objectiveIsReached : Bool
}

public typealias KpiResultsDictionary = [KpiEnum: KpiResult]
