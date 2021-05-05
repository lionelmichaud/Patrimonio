//
//  BarChartView+Extensions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Extension de BarChartView pour customizer la configuration des Graph de l'appli

extension BarChartView {
    
    /// Création d'un BarChartView avec une présentation customisée
    /// - Parameter title: Titre du graphique
    convenience init(title               : String,
                     smallLegend         : Bool = true,
                     axisFormatterChoice : AxisFormatterChoice) {
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
        self.drawValueAboveBarEnabled  = false
        self.drawBarShadowEnabled      = false
        self.fitBars                   = true
        self.highlightFullBarEnabled   = false
        self.gridBackgroundColor       = NSUIColor.black
        
        //: ### xAxis
        let xAxis = self.xAxis
        xAxis.enabled                   = true
        xAxis.drawLabelsEnabled         = true
        xAxis.labelFont                 = ChartThemes.ChartDefaults.smallLabelFont
        xAxis.labelTextColor            = ChartThemes.DarkChartColors.labelTextColor
        xAxis.labelPosition             = .bottom // .insideChart
        xAxis.labelRotationAngle        = -90
        xAxis.granularityEnabled        = true
        xAxis.granularity               = 1
        xAxis.labelCount                = 200
        xAxis.drawGridLinesEnabled      = true
        xAxis.drawAxisLineEnabled       = true
        
        //: ### RightAxis
        let rightAxis = self.rightAxis
        rightAxis.enabled = false
        
        //: ### LeftAxis
        let leftAxis = self.leftAxis
        leftAxis.enabled              = true
        leftAxis.labelFont            = ChartThemes.ChartDefaults.smallLabelFont
        leftAxis.labelTextColor       = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.valueFormatter       = axisFormatterChoice.IaxisFormatter()
        leftAxis.drawGridLinesEnabled = true
        leftAxis.drawZeroLineEnabled  = false

        //: ### Legend
        let legend = self.legend
        legend.enabled             = true
        legend.font                = smallLegend ? ChartThemes.ChartDefaults.smallLegendFont : ChartThemes.ChartDefaults.largeLegendFont
        legend.textColor           = ChartThemes.DarkChartColors.legendColor
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        //: ### Description
        self.chartDescription?.text = title
        self.chartDescription?.enabled = true
        
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

// MARK: - Extension de LineChartView pour customizer la configuration des Graph de l'appli

extension ScatterChartView {

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
        xAxis.drawGridLinesEnabled     = false
        xAxis.drawAxisLineEnabled      = true

        //: ### LeftAxis
        let leftAxis = self.leftAxis
        leftAxis.enabled               = true
        leftAxis.labelFont             = ChartThemes.ChartDefaults.smallLabelFont
        leftAxis.labelTextColor        = ChartThemes.DarkChartColors.labelTextColor
        leftAxis.valueFormatter        = axisFormatterChoice.IaxisFormatter()
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.drawZeroLineEnabled   = false
        leftAxis.axisMaxLabels         = 4
        leftAxis.granularity           = 1
        leftAxis.granularityEnabled    = true
        leftAxis.labelPosition         = .outsideChart
        //leftAxis.maxWidth              = 100

        //: ### RightAxis
        let rightAxis = self.rightAxis
        rightAxis.enabled              = false
        rightAxis.labelFont            = ChartThemes.ChartDefaults.smallLabelFont
        rightAxis.labelTextColor       = #colorLiteral(red     : 1, green     : 0.1474981606, blue     : 0, alpha     : 1)
        leftAxis.valueFormatter        = axisFormatterChoice.IaxisFormatter()
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
        self.chartDescription?.text = title
        self.chartDescription?.enabled = true
    }
}

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
        self.chartDescription?.text = title
        self.chartDescription?.enabled = true
    }
}

// MARK: - Extension de CombinedChartView pour customizer la configuration des Graph de l'appli

extension CombinedChartView {
    
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
        leftAxis.valueFormatter        = leftAxisFormatterChoice.IaxisFormatter()
        //        leftAxis.axisMaximum = 200.0
        //        leftAxis.axisMinimum = 0.0
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.drawZeroLineEnabled   = false
        
        //: ### RightAxis
        let rightAxis = self.rightAxis
        rightAxis.enabled              = true
        rightAxis.labelFont            = ChartThemes.ChartDefaults.smallLabelFont
        rightAxis.labelTextColor       = #colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)
        rightAxis.valueFormatter       = rightAxisFormatterChoice.IaxisFormatter()
        rightAxis.axisMinimum          = 0.0
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
        self.chartDescription?.text = title
        self.chartDescription?.enabled = true
    }
}
