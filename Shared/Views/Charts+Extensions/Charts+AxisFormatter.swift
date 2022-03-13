//
//  Charts+AxisFormater.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import Foundation
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Choix du formatteur de valeur à appliquer sur un axe Y

enum AxisFormatterChoice {
    case k€
    case largeValue (appendix: String?, min3Digit: Bool)
    case percent
    case name (names: [String])
    case none

    func IaxisFormatter() -> Charts.IAxisValueFormatter? {
        switch self {
            case .k€:
                return Kilo€Formatter()
            case .largeValue(let appendix, let minDigit):
                return LargeValueFormatter(appendix: appendix, min3digit: minDigit)
            case .percent:
                return PercentFormatter()
            case .name(let names):
                return NamedValueFormatter(names: names)
            case .none:
                return nil
        }
    }
}
