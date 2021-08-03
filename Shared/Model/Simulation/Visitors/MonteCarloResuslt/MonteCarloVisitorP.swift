//
//  MonteCarloVisitor.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 13/05/2021.
//

import Foundation

/// The Visitor Interface declares a set of visiting methods that correspond to
/// component classes. The signature of a visiting method allows the visitor to
/// identify the exact class of the component that it's dealing with.
protocol MonteCarloVisitorP {
    // Elements de MONTE-CARLO RESULT
    func visit(element: SimulationResultTable)
    func visit(element: SimulationResultLine)
    func visit(element: DictionaryOfAdultRandomProperties)
}
