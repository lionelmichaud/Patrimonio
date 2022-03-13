//
//  HorizontalBarChartView+Extension.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 05/01/2022.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Extension de CombinedChartView pour customizer la configuration des Graph de l'appli

extension HorizontalBarChartView {
    
    /// Création d'un LineChartView avec une présentation customisée
    /// - Parameter title: Titre du graphique
    convenience init(title                    : String,
                     smallLegend              : Bool = true,
                     leftAxisFormatterChoice  : AxisFormatterChoice = .none,
                     rightAxisFormatterChoice : AxisFormatterChoice = .none) {
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
        self.drawBordersEnabled        = false
        self.drawValueAboveBarEnabled  = false
        self.drawBarShadowEnabled      = false
        self.fitBars                   = true
        self.highlightFullBarEnabled   = false
        //self.maxVisibleCount = 60
        
        //: ### xAxis value formatter
        let xAxisValueFormatter = NamedValueFormatter()
        
        //: ### xAxis
        let xAxis = self.xAxis
        xAxis.drawAxisLineEnabled  = true
        xAxis.labelPosition        = .bottom
        xAxis.labelFont            = ChartThemes.ChartDefaults.largeLabelFont
        xAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        xAxis.granularityEnabled   = false
        xAxis.granularity          = 1
        xAxis.labelCount           = 200
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled  = true
        xAxis.valueFormatter       = xAxisValueFormatter
        //xAxis.wordWrapEnabled      = true
        //xAxis.wordWrapWidthPercent = 0.5
        //xAxis.axisMinimum         = 0
        
        //: ### LeftAxis
        let leftAxis = self.leftAxis
        leftAxis.enabled              = true
        leftAxis.drawAxisLineEnabled  = true
        leftAxis.drawGridLinesEnabled = true
        leftAxis.labelFont            = ChartThemes.ChartDefaults.largeLabelFont
        leftAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.granularityEnabled   = true // autoriser la réducion du nombre de label
        leftAxis.valueFormatter       = leftAxisFormatterChoice.IaxisFormatter()
        
        //: ### RightAxis
        let rightAxis = self.rightAxis
        rightAxis.enabled              = true
        rightAxis.drawAxisLineEnabled  = true
        rightAxis.drawGridLinesEnabled = false
        rightAxis.labelFont            = ChartThemes.ChartDefaults.largeLabelFont
        rightAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        rightAxis.granularityEnabled   = true // autoriser la réducion du nombre de label
        rightAxis.valueFormatter       = rightAxisFormatterChoice.IaxisFormatter()
        
        //: ### Legend
        let legend = self.legend
        legend.enabled             = false
        legend.font                = smallLegend ? ChartThemes.ChartDefaults.smallLegendFont : ChartThemes.ChartDefaults.largeLegendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.formSize            = 8
        legend.drawInside          = false
        legend.horizontalAlignment = .left
        legend.verticalAlignment   = .bottom
        legend.orientation         = .horizontal
        legend.xEntrySpace         = 4
        
        #if os(iOS) || os(tvOS)
        //: ## bulle d'info
        let marker = ExpenseMarkerView(color              : ChartThemes.BallonColors.color,
                                       font               : ChartThemes.ChartDefaults.baloonfont,
                                       textColor          : ChartThemes.BallonColors.textColor,
                                       insets             : UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                       xAxisValueFormatter: self.xAxis.valueFormatter!,
                                       yAxisValueFormatter: self.leftAxis.valueFormatter!)
        marker.chartView = self
        marker.minimumSize = CGSize(width: 80, height: 40)
        self.marker = marker
        #endif
        
        self.fitBars = true
        
        self.chartDescription?.text    = title
        self.chartDescription?.enabled = true
        self.chartDescription?.font    = .systemFont(ofSize : 13)
    }
}
