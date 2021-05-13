//
//  CashFlowVisitor.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/05/2021.
//

import Foundation

/// The Visitor Interface declares a set of visiting methods that correspond to
/// component classes. The signature of a visiting method allows the visitor to
/// identify the exact class of the component that it's dealing with.
protocol CashFlowVisitor {
    // Elements de CASH FLOW
    func visit(element: CashFlowArray)
    func visit(element: CashFlowLine)
    func visit(element: ValuedRevenues)
    func visit(element: ValuedTaxes)
    func visit(element: SciCashFlowLine)
    func visit(element: SciCashFlowLine.Revenues)
}
