//
//  MonteCarloVisitable.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 13/05/2021.
//

import Foundation

/// The Component interface declares an `accept` method that should take the
/// base visitor interface as an argument.
protocol MonteCarloVisitableP {
    func accept(_ visitor: MonteCarloVisitorP)
}
