//
//  LineChartDataSet+Extension.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Extension de LineChartDataSet pour customizer la configuration du tracé de courbe

public extension LineChartDataSet {
    convenience init (entries   : [ChartDataEntry]?,
                      label     : String,
                      color     : NSUIColor,
                      lineWidth : Double = 2.0) {
        self.init(entries: entries, label: label)
        self.axisDependency        = .left
        self.colors                = [color]
        self.circleColors          = [color]
        self.lineWidth             = lineWidth
        self.circleRadius          = 3.0
        self.fillAlpha             = 65 / 255.0
        self.fillColor             = color
        self.highlightColor        = color
        self.highlightEnabled      = true
        self.drawCircleHoleEnabled = false
    }
}
