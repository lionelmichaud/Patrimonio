//
//  BubbleChartView+Extension.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 05/01/2022.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Extension de BubbleChartView pour customizer la configuration des Graph de l'appli

extension BubbleChartView {
    /// Création d'un BubbleChartView avec une présentation customisée
    /// - Parameter title: Titre du graphique
    convenience init(title                   : String,
                     legendEnabled           : Bool                = true,
                     legendPosition          : LengendPosition     = .bottom,
                     smallLegend             : Bool                = true,
                     leftAxisFormatterChoice : AxisFormatterChoice = .none,
                     xAxisFormatterChoice    : AxisFormatterChoice = .none) {
        self.init()
        
        //: ### General
        self.pinchZoomEnabled          = true
        self.doubleTapToZoomEnabled    = true
        self.dragEnabled               = true
        self.drawGridBackgroundEnabled = true
        self.gridBackgroundColor       = ChartThemes.DarkChartColors.gridBackgroundColor
        self.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        self.borderColor               = ChartThemes.DarkChartColors.borderColor
        self.borderLineWidth           = 1.0
        self.drawBordersEnabled        = true
        self.gridBackgroundColor       = NSUIColor.black
        self.setScaleEnabled(true)
        
        //: ### xAxis
        let xAxis = self.xAxis
        xAxis.enabled              = true
        xAxis.drawLabelsEnabled    = true
        xAxis.labelFont            = ChartThemes.ChartDefaults.xLargeLabelFont
        xAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        xAxis.valueFormatter       = xAxisFormatterChoice.IaxisFormatter()
        xAxis.labelPosition        = .bottom // .insideChart
        xAxis.labelRotationAngle   = 0
        xAxis.granularityEnabled   = true
        xAxis.granularity          = 1
        //xAxis.labelCount           = 200
        xAxis.drawGridLinesEnabled = true
        xAxis.drawAxisLineEnabled  = true
        xAxis.avoidFirstLastClippingEnabled = false
        xAxis.spaceMin = 0.25
        xAxis.spaceMax = 0.25
        
        //: ### RightAxis
        let rightAxis = self.rightAxis
        rightAxis.enabled = false
        
        //: ### LeftAxis
        let leftAxis = self.leftAxis
        leftAxis.enabled              = true
        leftAxis.drawLabelsEnabled    = true
        leftAxis.labelFont            = ChartThemes.ChartDefaults.xLargeLabelFont
        leftAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.valueFormatter       = leftAxisFormatterChoice.IaxisFormatter()
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawZeroLineEnabled  = false
        leftAxis.granularityEnabled   = true
        leftAxis.granularity          = 1
        leftAxis.spaceMin = 0.25
        leftAxis.spaceMax = 0.25
        
        //: ### Legend
        let legend = self.legend
        legend.enabled             = legendEnabled
        legend.font                = smallLegend ? ChartThemes.ChartDefaults.smallLegendFont : ChartThemes.ChartDefaults.largeLegendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = false
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
        self.chartDescription?.text    = title
        self.chartDescription?.enabled = true
        self.chartDescription?.font    = ChartThemes.ChartDefaults.largeLegendFont
        
        // bulle d'info
        let marker = DateValueMarkerView(color               : ChartThemes.BallonColors.color,
                                         font                : ChartThemes.ChartDefaults.baloonfont,
                                         textColor           : ChartThemes.BallonColors.textColor,
                                         insets              : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                         xAxisValueFormatter : self.xAxis.valueFormatter!,
                                         yAxisValueFormatter : self.leftAxis.valueFormatter!)
        marker.chartView   = self
        marker.minimumSize = CGSize(width : 80, height : 40)
        self.marker   = marker
    }
}
