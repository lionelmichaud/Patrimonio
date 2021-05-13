//
//  CsvVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/05/2021.
//

import Foundation

/// The Visitor Interface declares a set of visiting methods that correspond to
/// component classes. The signature of a visiting method allows the visitor to
/// identify the exact class of the component that it's dealing with.
protocol BalanceSheetVisitor {
    // Elements de Bilan
    func visit(element: BalanceSheetArray)
    func visit(element: BalanceSheetLine)
    func visit(element: ValuedAssets)
    func visit(element: ValuedLiabilities)
}
