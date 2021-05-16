//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 16/05/2021.
//

import Foundation
import Statistics

/// The Visitor Interface declares a set of visiting methods that correspond to
/// component classes. The signature of a visiting method allows the visitor to
/// identify the exact class of the component that it's dealing with.
protocol HistogramChartVisitorP {
    // Elements de CASH FLOW
    func buildChart(element: Histogram)
}
