//
//  PatrimoineSummaryRiskChartView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/01/2022.
//

import SwiftUI
import AppFoundation
import PatrimoineModel
import Ownership
import AssetsModel
import Charts

struct PatrimoineSummaryRiskChartView: View {
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    @State private var evaluationContext      : EvaluationContext = .patrimoine

    var body: some View {
        VStack {
            HStack {
                PatrimoineRiskChartView(patrimoine        : patrimoine,
                                        year              : Int(uiState.patrimoineViewState.evalDate),
                                        evaluationContext : evaluationContext)
                PatrimoineLiquidityChartView(patrimoine        : patrimoine,
                                             year              : Int(uiState.patrimoineViewState.evalDate),
                                             evaluationContext : evaluationContext)
            }
            HStack {
                PatrimoineBubbleChartView(patrimoine        : patrimoine,
                                          year              : Int(uiState.patrimoineViewState.evalDate),
                                          evaluationContext : evaluationContext)
            }
        }
    }
}

struct PatrimoineRiskChartView: View {
    var patrimoine        : Patrimoin
    var year              : Int
    var evaluationContext : EvaluationContext
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            PieChartTemplateView(chartDescription   : nil,
                                 centerText         : "REPARTITION\nDU PATRIMOINE\nPAR NIVEAU\nDE RISQUE\n(0 à 4)",
                                 descriptionEnabled : true,
                                 legendEnabled      : false,
                                 pieColors          : ChartThemes.riskColorsTable,
                                 data               : data)
            Text("Niveau de Risque").bold().padding()
        }.border(Color.white)
    }
    
    var data : [(label: String, value: Double)] {
        var dataEntries = [(label: String, value: Double)]()

        dataEntries =
        RiskLevel.allCases.map { level in
            var value = 0.0
            value += patrimoine.assets.freeInvests.items
                .sumOfValues(atEndOf: year, witRiskLevel : level)
            value += patrimoine.assets.periodicInvests.items
                .sumOfValues(atEndOf: year, witRiskLevel : level)
            value += patrimoine.assets.realEstates.items
                .sumOfValues(atEndOf: year, witRiskLevel : level)
            value += patrimoine.assets.scpis.items
                .sumOfValues(atEndOf: year, witRiskLevel : level)
            value += patrimoine.assets.sci.scpis.items
                .sumOfValues(atEndOf: year, witRiskLevel : level)
            return (label : "\(level.rawValue) : \(level.displayString)",
                    value : value)
        }
        return dataEntries
    }
}

struct PatrimoineLiquidityChartView: View {
    var patrimoine        : Patrimoin
    var year              : Int
    var evaluationContext : EvaluationContext

    var body: some View {
        ZStack(alignment: .topLeading) {
        PieChartTemplateView(chartDescription   : nil,
                             centerText         : "REPARTITION\nDU PATRIMOINE\nPAR NIVEAU\nDE LIQUIDITÉ\n(0 à 2)",
                             descriptionEnabled : true,
                             legendEnabled      : false,
                             pieColors          : ChartThemes.liquidityColorsTable,
                             data               : data)
            Text("Liquidité").bold().padding()
        }.border(Color.white)
    }
    
    var data : [(label: String, value: Double)] {
        var dataEntries = [(label: String, value: Double)]()
        
        dataEntries =
            LiquidityLevel.allCases.map { level in
                var value = 0.0
                value += patrimoine.assets.freeInvests.items
                    .sumOfValues(atEndOf: year, witLiquidityLevel : level)
                value += patrimoine.assets.periodicInvests.items
                    .sumOfValues(atEndOf: year, witLiquidityLevel : level)
                value += patrimoine.assets.realEstates.items
                    .sumOfValues(atEndOf: year, witLiquidityLevel : level)
                value += patrimoine.assets.scpis.items
                    .sumOfValues(atEndOf: year, witLiquidityLevel : level)
                value += patrimoine.assets.sci.scpis.items
                    .sumOfValues(atEndOf: year, witLiquidityLevel : level)
                return (label : "\(level.rawValue) : \(level.displayString)",
                        value : value)
            }
        return dataEntries
    }
}

struct PatrimoineBubbleChartView: View {
    var patrimoine        : Patrimoin
    var year              : Int
    var evaluationContext : EvaluationContext

    var body: some View {
        HStack {
            Text("Liquidité").bold().rotationEffect(.degrees(-90))
            VStack {
                BubbleChartTemplateView(title                   : "",
                                        legendEnabled           : false,
                                        legendPosition          : .left,
                                        smallLegend             : true,
                                        averagesLinesEnabled    : true,
                                        leftAxisFormatterChoice : .name(names: LiquidityLevel.allCases.map { $0.displayString }),
                                        xAxisFormatterChoice    : .name(names: RiskLevel.allCases.map { $0.displayString }),
                                        data                    : data)
                Text("Niveau de Risque").bold()
            }
        }
        .padding([.bottom,.trailing]).border(Color.white)
    }
    
    var data : [(x: Double, y: Double, size: Double)] {
        var dataEntries      = [(x: Double, y: Double, size: Double)]()

        RiskLevel.allCases.forEach { risk in
            dataEntries += LiquidityLevel.allCases.map { liquidity in
                var value = 0.0
                value += patrimoine.assets.freeInvests.items
                    .sumOfValues(atEndOf           : year,
                                 witRiskLevel      : risk,
                                 witLiquidityLevel : liquidity)
                value += patrimoine.assets.periodicInvests.items
                    .sumOfValues(atEndOf           : year,
                                 witRiskLevel      : risk,
                                 witLiquidityLevel : liquidity)
                value += patrimoine.assets.realEstates.items
                    .sumOfValues(atEndOf           : year,
                                 witRiskLevel      : risk,
                                 witLiquidityLevel : liquidity)
                value += patrimoine.assets.scpis.items
                    .sumOfValues(atEndOf           : year,
                                 witRiskLevel      : risk,
                                 witLiquidityLevel : liquidity)
                value += patrimoine.assets.sci.scpis.items
                    .sumOfValues(atEndOf           : year,
                                 witRiskLevel      : risk,
                                 witLiquidityLevel : liquidity)
                return (x    : risk.rawValue.double(),
                        y    : liquidity.rawValue.double(),
                        size : value)
            }
        }
        
        return dataEntries
    }
}

struct PatrimoineSummaryRiskChartView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return PatrimoineSummaryRiskChartView()
            .preferredColorScheme(.dark)
            .environmentObject(patrimoineTest)
            .environmentObject(uiStateTest)
    }
}
