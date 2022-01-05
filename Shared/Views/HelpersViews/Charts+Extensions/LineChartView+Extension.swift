//
//  LineChartView+Extension.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 05/01/2022.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Extension de LineChartView pour customizer la configuration des Graph de l'appli

extension LineChartView {
    
    /// Création d'un LineChartView avec une présentation customisée
    /// - Parameter title: Titre du graphique
    convenience init(title               : String,
                     smallLegend         : Bool = true,
                     axisFormatterChoice : AxisFormatterChoice) {
        self.init()
        
        //: ### General
        self.pinchZoomEnabled          = true
        self.doubleTapToZoomEnabled    = true
        self.dragEnabled               = true
        self.setScaleEnabled(true)
        self.drawGridBackgroundEnabled = false
        self.gridBackgroundColor       = ChartThemes.DarkChartColors.gridBackgroundColor
        self.backgroundColor           = ChartThemes.DarkChartColors.backgroundColor
        self.borderColor               = ChartThemes.DarkChartColors.borderColor
        self.borderLineWidth           = 1.0
        self.drawBordersEnabled        = true
        
        //: ### xAxis
        let xAxis = self.xAxis
        xAxis.enabled                  = true
        xAxis.drawLabelsEnabled        = true
        xAxis.labelFont                = ChartThemes.ChartDefaults.smallLabelFont
        xAxis.labelTextColor           = ChartThemes.DarkChartColors.labelTextColor
        xAxis.labelPosition            = .bottom // .insideChart
        xAxis.labelRotationAngle       = -90
        xAxis.granularityEnabled       = true
        xAxis.granularity              = 1
        xAxis.labelCount               = 200
        //        xAxis.valueFormatter = IndexAxisValueFormatter(values : months)
        //        xAxis.setLabelCount(months.count, force               : false)
        xAxis.drawGridLinesEnabled     = true
        xAxis.drawAxisLineEnabled      = true
        //        xAxis.axisMinimum    = 0
        
        //: ### LeftAxis
        let leftAxis = self.leftAxis
        leftAxis.enabled               = true
        leftAxis.labelFont             = ChartThemes.ChartDefaults.smallLabelFont
        leftAxis.labelTextColor        = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.valueFormatter        = axisFormatterChoice.IaxisFormatter()
        //        leftAxis.axisMaximum = 200.0
        //        leftAxis.axisMinimum = 0.0
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.drawZeroLineEnabled   = false
        
        //: ### RightAxis
        let rightAxis = self.rightAxis
        rightAxis.enabled              = false
        rightAxis.labelFont            = ChartThemes.ChartDefaults.smallLabelFont
        rightAxis.labelTextColor       = #colorLiteral(red     : 1, green     : 0.1474981606, blue     : 0, alpha     : 1)
        leftAxis.valueFormatter        = axisFormatterChoice.IaxisFormatter()
        //        rightAxis.axisMaximum          = 900.0
        //        rightAxis.axisMinimum          = -200.0
        rightAxis.drawGridLinesEnabled = false
        rightAxis.granularityEnabled   = false
        
        //: ### Legend
        let legend = self.legend
        legend.font                = smallLegend ? ChartThemes.ChartDefaults.smallLegendFont : ChartThemes.ChartDefaults.largeLegendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        //: ### ajouter un Marker
        let marker = XYMarkerView(color: ChartThemes.BallonColors.color,
                                  font: ChartThemes.ChartDefaults.baloonfont,
                                  textColor: ChartThemes.BallonColors.textColor,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter: xAxis.valueFormatter!,
                                  yAxisValueFormatter: leftAxis.valueFormatter!)
        marker.chartView = self
        marker.minimumSize = CGSize(width: 80, height: 40)
        self.marker = marker
        
        //: ### Description
        self.chartDescription?.text    = title
        self.chartDescription?.enabled = true
        self.chartDescription?.font    = ChartThemes.ChartDefaults.largeLegendFont
    }
}
