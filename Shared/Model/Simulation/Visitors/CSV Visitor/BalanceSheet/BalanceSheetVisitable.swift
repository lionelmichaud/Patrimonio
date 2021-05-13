//
//  VisitorProtocol.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 09/05/2021.
//

import Foundation

/// The Component interface declares an `accept` method that should take the
/// base visitor interface as an argument.
protocol BalanceSheetVisitable {
    func accept(_ visitor: BalanceSheetVisitor)
}
