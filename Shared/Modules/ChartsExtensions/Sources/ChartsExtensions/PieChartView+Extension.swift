//
//  PieChartView+Extension.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 05/01/2022.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Extension de PieChartView pour customizer la configuration des Graph de l'appli

public extension PieChartView {
    
    /// Création d'un LineChartView avec une présentation customisée
    /// - Parameter title: Titre du graphique
    convenience init(chartDescription   : String?,
                     centerText         : String?,
                     descriptionEnabled : Bool = true,
                     legendEnabled      : Bool = true,
                     legendPosition     : LengendPosition = .bottom,
                     smallLegend        : Bool = true) {
        self.init()
        
        //: ### General
        self.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        self.holeColor                 = ChartThemes.DarkChartColors.backgroundColor
        self.drawSlicesUnderHoleEnabled = true
        self.drawHoleEnabled            = true
        self.drawCenterTextEnabled      = centerText != nil
        self.rotationAngle              = 0.0
        //        self.centerText                 = title
        
        if let centerText = centerText {
            let paragraphStyle           = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.lineBreakMode = .byTruncatingTail
            paragraphStyle.alignment     = .center
            
            let attrString = NSMutableAttributedString(string: centerText)
            attrString.setAttributes([.foregroundColor: ChartThemes.DarkChartColors.legendColor,
                                      .font: ChartThemes.ChartDefaults.titleFont,
                                      .paragraphStyle: paragraphStyle],
                                     range: NSRange(location: 0, length: attrString.length))
            self.centerAttributedText = attrString
        }
        
        //: ### Legend
        let legend = self.legend
        legend.enabled             = legendEnabled
        legend.font                = smallLegend ? ChartThemes.ChartDefaults.smallLegendFont : ChartThemes.ChartDefaults.largeLegendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = true
        switch legendPosition {
            case .left:
                legend.orientation         = .vertical
                legend.verticalAlignment   = .center
            case .bottom:
                legend.orientation         = .horizontal
                legend.verticalAlignment   = .bottom
        }
        legend.horizontalAlignment = .left
        legend.formSize = CGFloat(12.0)
        
        //: ### Description
        self.chartDescription?.enabled = descriptionEnabled
        self.chartDescription?.text    = chartDescription
        self.chartDescription?.font    = ChartThemes.ChartDefaults.largeLegendFont
        
        // bulle d'info
        let marker = PieMarkerView(color               : ChartThemes.BallonColors.color,
                                   font                : ChartThemes.ChartDefaults.baloonfont,
                                   textColor           : ChartThemes.BallonColors.textColor,
                                   insets              : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView   = self
        marker.minimumSize = CGSize(width : 80, height : 40)
        self.marker   = marker
    }
}
