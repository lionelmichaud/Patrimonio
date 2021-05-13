//
//  File.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/05/2021.
//

import Foundation

/// The Component interface declares an `accept` method that should take the
/// base visitor interface as an argument.
protocol CashFlowVisitable {
    func accept(_ visitor: CashFlowVisitor)
}
