//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 13/03/2022.
//

import SwiftUI
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Themes graphiques

public struct ChartThemes {
    public struct BallonColors { // UIColor
        public static let color     = #colorLiteral(red: 0.5704585314, green: 0.5704723597, blue: 0.5704649091, alpha: 1)
        public static let textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }

    public struct DarkChartColors { // UIColor
        public static let gridColor           = #colorLiteral(red          : 0.6000000238, green          : 0.6000000238, blue          : 0.6000000238, alpha          : 1)
        public static let gridBackgroundColor = #colorLiteral(red     : 0, green     : 0, blue     : 0, alpha     : 1)
        public static let backgroundColor     = #colorLiteral(red     : 0, green     : 0, blue     : 0, alpha     : 1)
        public static let borderColor         = #colorLiteral(red     : 0, green     : 0, blue     : 0, alpha     : 1)
        public static let valueColor          = #colorLiteral(red     : 1, green     : 1, blue     : 1, alpha     : 1)
        public static let legendColor         = #colorLiteral(red     : 1, green     : 1, blue     : 1, alpha     : 1)
        public static let labelTextColor      = #colorLiteral(red     : 1, green     : 1, blue     : 1, alpha     : 1)
    }

    public struct LightChartColors { // UIColor
        public static let gridColor           = #colorLiteral(red          : 0.6000000238, green          : 0.6000000238, blue          : 0.6000000238, alpha          : 1)
        public static let gridBackgroundColor = #colorLiteral(red: 0.9171036869, green: 0.9171036869, blue: 0.9171036869, alpha: 1)
        public static let backgroundColor     = #colorLiteral(red     : 1, green     : 1, blue     : 1, alpha     : 1)
        public static let borderColor         = #colorLiteral(red         : 1, green         : 1, blue         : 1, alpha         : 1)
        public static let valueColor          = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        public static let legendColor         = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        public static let labelTextColor      = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }

    public struct ChartDefaults {
        public static let smallLabelFont  : NSUIFont = .systemFont(ofSize: 12)
        public static let largeLabelFont  : NSUIFont = .systemFont(ofSize: 13)
        public static let xLargeLabelFont : NSUIFont = .systemFont(ofSize: 14)
        public static let smallLegendFont : NSUIFont = .systemFont(ofSize: 11)
        public static let largeLegendFont : NSUIFont = .systemFont(ofSize: 13)
        public static let titleFont       : NSUIFont = .systemFont(ofSize: 16, weight: .bold)
        public static let baloonfont      : NSUIFont = .systemFont(ofSize: 14)
        public static let valueFont       : NSUIFont = .systemFont(ofSize: 14)
    }

    public static let positiveColorsTable  : [NSUIColor] = [#colorLiteral(red  : 0.1294117719, green  : 0.2156862766, blue  : 0.06666667014, alpha  : 1),#colorLiteral(red  : 0.1960784346, green  : 0.3411764801, blue  : 0.1019607857, alpha  : 1),#colorLiteral(red  : 0.2745098174, green  : 0.4862745106, blue  : 0.1411764771, alpha  : 1),#colorLiteral(red  : 0.3411764801, green  : 0.6235294342, blue  : 0.1686274558, alpha  : 1),#colorLiteral(red  : 0.4666666687, green  : 0.7647058964, blue  : 0.2666666806, alpha  : 1),#colorLiteral(red  : 0.5843137503, green  : 0.8235294223, blue  : 0.4196078479, alpha  : 1),#colorLiteral(red  : 0.721568644, green  : 0.8862745166, blue  : 0.5921568871, alpha  : 1),#colorLiteral(red  : 0.05882352963, green  : 0.180392161, blue  : 0.2470588237, alpha  : 1),#colorLiteral(red  : 0.1019607857, green  : 0.2784313858, blue  : 0.400000006, alpha  : 1),#colorLiteral(red  : 0.1411764771, green  : 0.3960784376, blue  : 0.5647059083, alpha  : 1),#colorLiteral(red  : 0.1764705926, green  : 0.4980392158, blue  : 0.7568627596, alpha  : 1),#colorLiteral(red  : 0.2392156869, green  : 0.6745098233, blue  : 0.9686274529, alpha  : 1),#colorLiteral(red  : 0.2588235438, green  : 0.7568627596, blue  : 0.9686274529, alpha  : 1),#colorLiteral(red  : 0.4745098054, green  : 0.8392156959, blue  : 0.9764705896, alpha  : 1),#colorLiteral(red  : 0.06274510175, green  : 0, blue  : 0.1921568662, alpha  : 1),#colorLiteral(red  : 0.1215686277, green  : 0.01176470611, blue  : 0.4235294163, alpha  : 1),#colorLiteral(red  : 0.1215686277, green  : 0.01176470611, blue  : 0.4235294163, alpha  : 1),#colorLiteral(red  : 0.1764705926, green  : 0.01176470611, blue  : 0.5607843399, alpha  : 1),#colorLiteral(red  : 0.2196078449, green  : 0.007843137719, blue  : 0.8549019694, alpha  : 1),#colorLiteral(red  : 0.3647058904, green  : 0.06666667014, blue  : 0.9686274529, alpha  : 1),#colorLiteral(red  : 0.5568627715, green  : 0.3529411852, blue  : 0.9686274529, alpha  : 1),#colorLiteral(red  : 1, green  : 1, blue  : 1, alpha  : 1),#colorLiteral(red  : 0.8039215803, green  : 0.8039215803, blue  : 0.8039215803, alpha  : 1),#colorLiteral(red  : 0.6000000238, green  : 0.6000000238, blue  : 0.6000000238, alpha  : 1),#colorLiteral(red  : 0.501960814, green  : 0.501960814, blue  : 0.501960814, alpha  : 1),#colorLiteral(red  : 0.2549019754, green  : 0.2745098174, blue  : 0.3019607961, alpha  : 1),#colorLiteral(red  : 0.1686089337, green  : 0.1686392725, blue  : 0.1686022878, alpha  : 1),#colorLiteral(red  : 0.7254902124, green  : 0.4784313738, blue  : 0.09803921729, alpha  : 1),#colorLiteral(red  : 0.5058823824, green  : 0.3372549117, blue  : 0.06666667014, alpha  : 1),#colorLiteral(red  : 0.3098039329, green  : 0.2039215714, blue  : 0.03921568766, alpha  : 1),#colorLiteral(red  : 0.2554336918, green  : 0.1694213438, blue  : 0.0335564099, alpha  : 1),#colorLiteral(red  : 0.1294117719, green  : 0.2156862766, blue  : 0.06666667014, alpha  : 1),#colorLiteral(red  : 0.1960784346, green  : 0.3411764801, blue  : 0.1019607857, alpha  : 1),#colorLiteral(red  : 0.2745098174, green  : 0.4862745106, blue  : 0.1411764771, alpha  : 1),#colorLiteral(red  : 0.3411764801, green  : 0.6235294342, blue  : 0.1686274558, alpha  : 1),#colorLiteral(red  : 0.4666666687, green  : 0.7647058964, blue  : 0.2666666806, alpha  : 1),#colorLiteral(red  : 0.5843137503, green  : 0.8235294223, blue  : 0.4196078479, alpha  : 1),#colorLiteral(red  : 0.721568644, green  : 0.8862745166, blue  : 0.5921568871, alpha  : 1)]
    public static let negativeColorsTable  : [NSUIColor] = [#colorLiteral(red  : 0.3176470697, green  : 0.07450980693, blue  : 0.02745098062, alpha  : 1),#colorLiteral(red  : 0.521568656, green  : 0.1098039225, blue  : 0.05098039284, alpha  : 1),#colorLiteral(red  : 0.7450980544, green  : 0.1568627506, blue  : 0.07450980693, alpha  : 1),#colorLiteral(red  : 0.9254902005, green  : 0.2352941185, blue  : 0.1019607857, alpha  : 1),#colorLiteral(red  : 0.9411764741, green  : 0.4980392158, blue  : 0.3529411852, alpha  : 1),#colorLiteral(red  : 0.5058823824, green  : 0.3372549117, blue  : 0.06666667014, alpha  : 1),#colorLiteral(red  : 0.7254902124, green  : 0.4784313738, blue  : 0.09803921729, alpha  : 1),#colorLiteral(red  : 0.9529411793, green  : 0.6862745285, blue  : 0.1333333403, alpha  : 1),#colorLiteral(red  : 0.9764705896, green  : 0.850980401, blue  : 0.5490196347, alpha  : 1),#colorLiteral(red  : 0.2196078449, green  : 0.007843137719, blue  : 0.8549019694, alpha  : 1),#colorLiteral(red  : 0.3647058904, green  : 0.06666667014, blue  : 0.9686274529, alpha  : 1),#colorLiteral(red  : 0.5568627715, green  : 0.3529411852, blue  : 0.9686274529, alpha  : 1)]
    public static let pieChartColorsTable  : [NSUIColor] = [#colorLiteral(red  : 0.2745098174, green  : 0.4862745106, blue  : 0.1411764771, alpha  : 1),#colorLiteral(red  : 0.1764705926, green  : 0.4980392158, blue  : 0.7568627596, alpha  : 1),#colorLiteral(red  : 0.7450980544, green  : 0.1568627506, blue  : 0.07450980693, alpha  : 1),#colorLiteral(red  : 0.7254902124, green  : 0.4784313738, blue  : 0.09803921729, alpha  : 1),#colorLiteral(red  : 0.5568627715, green  : 0.3529411852, blue  : 0.9686274529, alpha  : 1),#colorLiteral(red  : 0.9254902005, green  : 0.2352941185, blue  : 0.1019607857, alpha  : 1),#colorLiteral(red  : 1, green  : 0.5212053061, blue  : 1, alpha  : 1),#colorLiteral(red  : 0.2381011844, green  : 0.6540691257, blue  : 0.4755768776, alpha  : 1),#colorLiteral(red  : 0.9411764741, green  : 0.4980392158, blue  : 0.3529411852, alpha  : 1),#colorLiteral(red  : 0.3647058904, green  : 0.06666667014, blue  : 0.9686274529, alpha  : 1),#colorLiteral(red  : 0.1294117719, green  : 0.2156862766, blue  : 0.06666667014, alpha  : 1),#colorLiteral(red  : 0.1411764771, green  : 0.3960784376, blue  : 0.5647059083, alpha  : 1),#colorLiteral(red  : 0.2196078449, green  : 0.007843137719, blue  : 0.8549019694, alpha  : 1),#colorLiteral(red  : 0.2549019754, green  : 0.2745098174, blue  : 0.3019607961, alpha  : 1),#colorLiteral(red  : 0.1686089337, green  : 0.1686392725, blue  : 0.1686022878, alpha  : 1),#colorLiteral(red  : 0.2554336918, green  : 0.1694213438, blue  : 0.0335564099, alpha  : 1)]
    public static let riskColorsTable      : [NSUIColor] = [#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1), #colorLiteral(red  : 0.3411764801, green  : 0.6235294342, blue  : 0.1686274558, alpha  : 1), #colorLiteral(red  : 0.9529411793, green  : 0.6862745285, blue  : 0.1333333403, alpha  : 1), #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1), #colorLiteral(red: 0.7578792735, green: 0, blue: 0, alpha: 1)]
    public static let liquidityColorsTable : [NSUIColor] = [#colorLiteral(red: 0.7578792735, green: 0, blue: 0, alpha: 1), #colorLiteral(red : 0.9529411793, green : 0.6862745285, blue : 0.1333333403, alpha : 1), #colorLiteral(red  : 0.1960784346, green  : 0.3411764801, blue  : 0.1019607857, alpha  : 1)]

    public static func positiveColors (number: Int) -> [NSUIColor] {
        var colorTable = [NSUIColor]()
        if number == 0 {
            return [positiveColorsTable[0]]
        } else {
            for i in 0...number-1 {
                colorTable.append(positiveColorsTable[i % positiveColorsTable.count])
            }
        }
        return colorTable
    }

    public static func negativeColors (number: Int) -> [NSUIColor] {
        var colorTable = [NSUIColor]()
        if number == 0 {
            return [negativeColorsTable[0]]
        } else {
            for i in 0...number-1 {
                colorTable.append(negativeColorsTable[i % negativeColorsTable.count])
            }
        }
        return colorTable
    }

    public static func colors (numberPositive: Int = 0, numberNegative: Int = 0) -> [NSUIColor] {
        var colorTable = [NSUIColor]()
        if numberPositive == 0 && numberNegative == 0 {
            return [positiveColorsTable[0]]
        } else {
            if numberPositive != 0 {
                for i in 0...numberPositive-1 {
                    colorTable.append(positiveColorsTable[i % positiveColorsTable.count])
                }
            }
            if numberNegative != 0 {
                for i in 0...numberNegative-1 {
                    colorTable.append(negativeColorsTable[i % negativeColorsTable.count])
                }
            }
        }
        return colorTable
    }

    public static let taxRateColorsTable: [NSUIColor] = [#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1),#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1),#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1),#colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1),#colorLiteral(red: 0.3176470697, green: 0.07450980693, blue: 0.02745098062, alpha: 1)]

    public static func taxRateColor(rate: Double) -> NSUIColor {
        switch rate * 100.0 {
            case 0.0 ..< 10.0:
                return taxRateColorsTable[0]
            case 10.0 ..< 20.0:
                return taxRateColorsTable[1]
            case 20.0 ..< 35.0:
                return taxRateColorsTable[2]
            case 35.0 ..< 45.0:
                return taxRateColorsTable[3]
            case 45.0...Double.infinity :
                return taxRateColorsTable[4]
            default:
                return #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
    }
}
