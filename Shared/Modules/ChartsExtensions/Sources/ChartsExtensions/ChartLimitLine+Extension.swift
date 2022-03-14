//
//  ChartLimitLine+Extension.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import Foundation
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Extension de ChartLimitLine pour customizer la configuration de la ligne limite

public extension ChartLimitLine {
    convenience init(limit        : Double,
                     label        : String,
                     labelPosition: LabelPosition,
                     lineColor    : NSUIColor) {
        self.init(limit: limit, label: label)
        self.lineWidth       = 2
        self.lineDashLengths = [10, 5]
        self.lineColor       = lineColor
        self.labelPosition   = .topRight
        self.valueFont       = ChartThemes.ChartDefaults.smallLabelFont
        self.valueTextColor  = .white
    }
}
