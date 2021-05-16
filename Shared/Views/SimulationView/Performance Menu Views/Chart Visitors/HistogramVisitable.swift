//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 16/05/2021.
//

import Foundation

/// The Component interface declares an `accept` method that should take the
/// base visitor interface as an argument.
protocol HistogramChartVisitableP {
    func accept(_ visitor: HistogramChartVisitorP)
}
