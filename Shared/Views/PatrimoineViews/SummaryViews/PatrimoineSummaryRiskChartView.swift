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
import FamilyModel
import Charts

let riskPopOverMessage =
    """
    Très élevé:\t\tProduit à taux fct répartition des actifs
    Elevé:\t\t\tProduit à taux fct répartition des actifs
    Moyen:\t\t\tSCPI, Produit à taux fct répartition des actifs
    Faible:\t\t\tImmobilier physique, Produit à taux fct répartition des actifs
    Très faible:\t\tTontine, Produit à taux garanti
    """

let liquidityPopOverMessage =
    """
    Elevé:\tLiquidité, Livret
    Moyen:\tSCPI, PEA, PEE, PER, Assurance Vie
    Faible:\tImmobilier, Tontine
    """

struct PatrimoineSummaryRiskChartView: View {
    static let tous     = "Tous"
    static let adults   = "Adultes"
    static let children = "Enfants"
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    @State private var evaluationContext      : EvaluationContext = .patrimoine
    @State private var selectedMembers        : String            = tous
    @State private var menuItems = [String]()

    var body: some View {
        VStack {
            HStack {
                CasePicker(pickedCase: $evaluationContext, label: "Context d'évaluation:")
                    .pickerStyle(MenuPickerStyle())
                Text(evaluationContext.displayString)
                    .padding(.trailing)
                
                Picker("Pour:", selection: $selectedMembers) {
                    ForEach(menuItems, id: \.self) { name in
                        Text(name)
                    }
                }.pickerStyle(MenuPickerStyle())
                Text(selectedMembers)
                
                Spacer()
            }.padding(.horizontal)
            
            HStack {
                PatrimoineRiskChartView(family            : family,
                                        patrimoine        : patrimoine,
                                        year              : Int(uiState.patrimoineViewState.evalDate),
                                        evaluationContext : evaluationContext,
                                        selectedMembers   : selectedMembers)
                PatrimoineLiquidityChartView(family            : family,
                                             patrimoine        : patrimoine,
                                             year              : Int(uiState.patrimoineViewState.evalDate),
                                             evaluationContext : evaluationContext,
                                             selectedMembers   : selectedMembers)
            }
            
            HStack {
                PatrimoineBubbleChartView(family            : family,
                                          patrimoine        : patrimoine,
                                          year              : Int(uiState.patrimoineViewState.evalDate),
                                          evaluationContext : evaluationContext,
                                          selectedMembers   : selectedMembers)
            }
        }
        .onAppear(perform: buildMenu)
    }
    
    private func buildMenu() {
        menuItems =
            [PatrimoineSummaryRiskChartView.tous] +
            [PatrimoineSummaryRiskChartView.adults] +
            [PatrimoineSummaryRiskChartView.children] +
            family.membersName
    }
}

struct PatrimoineRiskChartView: View {
    var family            : Family
    var patrimoine        : Patrimoin
    var year              : Int
    var evaluationContext : EvaluationContext
    var selectedMembers   : String

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
    
    private var data : [(label: String, value: Double)] {
        var dataEntries = [(label: String, value: Double)]()
        
        if !family.membersName.contains(selectedMembers) {
            var membersName : [String]

            switch selectedMembers {
                case PatrimoineSummaryRiskChartView.tous:
                    membersName = family.membersName
                    
                case PatrimoineSummaryRiskChartView.adults:
                    membersName = family.adultsName
                    
                case PatrimoineSummaryRiskChartView.children:
                    membersName = family.childrenName
                    
                default:
                    membersName = [ ]
            }
            
            dataEntries =
                RiskLevel.allCases.map { level in
                    var value = 0.0
                    membersName.forEach { name in
                        value += sum(for: name, witRiskLevel: level)
                    }
                    return (label : "\(level.rawValue) : \(level.displayString)",
                            value : value)
                }
            
        } else {
            dataEntries =
                RiskLevel.allCases.map { level in
                    let value = sum(for: selectedMembers, witRiskLevel: level)
                    return (label : "\(level.rawValue) : \(level.displayString)",
                            value : value)
                }
        }
        return dataEntries
    }
    
    private func sum(for name           : String,
                     witRiskLevel level : RiskLevel) -> Double {
        var value = 0.0
        value += patrimoine.assets.freeInvests.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : level,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.periodicInvests.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : level,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.realEstates.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : level,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.scpis.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : level,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.sci.scpis.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : level,
                         evaluationContext : evaluationContext)
        return value
    }
}

struct PatrimoineLiquidityChartView: View {
    var family            : Family
    var patrimoine        : Patrimoin
    var year              : Int
    var evaluationContext : EvaluationContext
    var selectedMembers   : String

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
    
    private var data : [(label: String, value: Double)] {
        var dataEntries = [(label: String, value: Double)]()
        
        if !family.membersName.contains(selectedMembers) {
            var membersName : [String]
            
            switch selectedMembers {
                case PatrimoineSummaryRiskChartView.tous:
                    membersName = family.membersName
                    
                case PatrimoineSummaryRiskChartView.adults:
                    membersName = family.adultsName
                    
                case PatrimoineSummaryRiskChartView.children:
                    membersName = family.childrenName
                    
                default:
                    membersName = [ ]
            }
            
            dataEntries =
                LiquidityLevel.allCases.map { level in
                    var value = 0.0
                    membersName.forEach { name in
                        value += sum(for: name, witLiquidityLevel: level)
                    }
                    return (label : "\(level.rawValue) : \(level.displayString)",
                            value : value)
                }
            
        } else {
            dataEntries =
                LiquidityLevel.allCases.map { level in
                    let value = sum(for: selectedMembers, witLiquidityLevel: level)
                    return (label : "\(level.rawValue) : \(level.displayString)",
                            value : value)
                }
        }
        return dataEntries
    }
    
    private func sum(for name                : String,
                     witLiquidityLevel level : LiquidityLevel) -> Double {
        var value = 0.0
        value += patrimoine.assets.freeInvests.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witLiquidityLevel : level,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.periodicInvests.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witLiquidityLevel : level,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.realEstates.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witLiquidityLevel : level,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.scpis.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witLiquidityLevel : level,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.sci.scpis.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witLiquidityLevel : level,
                         evaluationContext : evaluationContext)
        return value
    }
}

struct PatrimoineBubbleChartView: View {
    var family            : Family
    var patrimoine        : Patrimoin
    var year              : Int
    var evaluationContext : EvaluationContext
    var selectedMembers   : String
    @State private var showRiskInfoPopover   = false
    @State private var showLiquidInfoPopover = false
    
    var body: some View {
        HStack {
            HStack {
                Text("Liquidité").bold()
                Button(action: { self.showLiquidInfoPopover = true },
                       label : {
                        Image(systemName: "info.circle")
                       })
                    .rotationEffect(.degrees(90))
                    .popover(isPresented: $showLiquidInfoPopover) {
                        PopOverContentView(description: liquidityPopOverMessage)
                    }
            }.rotationEffect(.degrees(-90))
            
            VStack {
                BubbleChartTemplateView(title                   : nil,
                                        titleEnabled            : true,
                                        legendEnabled           : false,
                                        legendPosition          : .left,
                                        smallLegend             : true,
                                        averagesLinesEnabled    : true,
                                        leftAxisFormatterChoice : .name(names: LiquidityLevel.allCases.map { $0.displayString }),
                                        xAxisFormatterChoice    : .name(names: RiskLevel.allCases.map { $0.displayString }),
                                        markers                 : markers,
                                        data                    : data)
                HStack {
                    Text("Niveau de Risque").bold()
                    Button(action: { self.showRiskInfoPopover = true },
                           label : {
                            Image(systemName: "info.circle")
                           })
                        .popover(isPresented: $showRiskInfoPopover) {
                            PopOverContentView(description: riskPopOverMessage)
                        }
                }
            }
        }
        .padding([.bottom,.trailing]).border(Color.white)
    }
    
    private var markers : [[String]] {
        var membersName : [String]
        
        switch selectedMembers {
            case PatrimoineSummaryRiskChartView.tous:
                membersName = family.membersName
                
            case PatrimoineSummaryRiskChartView.adults:
                membersName = family.adultsName
                
            case PatrimoineSummaryRiskChartView.children:
                membersName = family.childrenName
                
            default:
                membersName = [selectedMembers]
        }
        
        return RiskLevel.allCases.map { risk -> [String] in
            LiquidityLevel.allCases.map { liquidity -> String in
                let markers = patrimoine.assets.namedValues(ownedBy           : membersName,
                                                            atEndOf           : year,
                                                            witRiskLevel      : risk,
                                                            witLiquidityLevel : liquidity,
                                                            evaluationContext : evaluationContext)
                
                return markers.map { namedValue in
                    "\(namedValue.name): \(namedValue.value.k€String)"
                }.joined(separator: "\n")
            }
        }
    }
    
    private var data : [(x: Double, y: Double, size: Double)] {
        var dataEntries = [(x: Double, y: Double, size: Double)]()
        
        if !family.membersName.contains(selectedMembers) {
            var membersName : [String]
            
            switch selectedMembers {
                case PatrimoineSummaryRiskChartView.tous:
                    membersName = family.membersName
                    
                case PatrimoineSummaryRiskChartView.adults:
                    membersName = family.adultsName
                    
                case PatrimoineSummaryRiskChartView.children:
                    membersName = family.childrenName
                    
                default:
                    membersName = [ ]
            }
            
            RiskLevel.allCases.forEach { risk in
                dataEntries +=
                    LiquidityLevel.allCases.map { liquidity in
                        var value = 0.0
                        membersName.forEach { name in
                            value += sum(for               : name,
                                         witRiskLevel      : risk,
                                         witLiquidityLevel : liquidity)
                        }
                        return (x    : risk.rawValue.double(),
                                y    : liquidity.rawValue.double(),
                                size : value)
                    }
            }
            
        } else {
            RiskLevel.allCases.forEach { risk in
                dataEntries +=
                    LiquidityLevel.allCases.map { liquidity in
                        let value = sum(for               : selectedMembers,
                                        witRiskLevel      : risk,
                                        witLiquidityLevel : liquidity)
                        return (x    : risk.rawValue.double(),
                                y    : liquidity.rawValue.double(),
                                size : value)
                    }
            }
        }
        
        return dataEntries
    }

    private func sum(for name                    : String,
                     witRiskLevel risk           : RiskLevel,
                     witLiquidityLevel liquidity : LiquidityLevel) -> Double {
        var value = 0.0
        value += patrimoine.assets.freeInvests.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : risk,
                         witLiquidityLevel : liquidity,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.periodicInvests.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : risk,
                         witLiquidityLevel : liquidity,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.realEstates.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : risk,
                         witLiquidityLevel : liquidity,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.scpis.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : risk,
                         witLiquidityLevel : liquidity,
                         evaluationContext : evaluationContext)
        value += patrimoine.assets.sci.scpis.items
            .sumOfValues(ownedBy           : name,
                         atEndOf           : year,
                         witRiskLevel      : risk,
                         witLiquidityLevel : liquidity,
                         evaluationContext : evaluationContext)
        return value
    }
}

struct PatrimoineSummaryRiskChartView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return PatrimoineSummaryRiskChartView()
            .preferredColorScheme(.dark)
            .environmentObject(familyTest)
            .environmentObject(patrimoineTest)
            .environmentObject(uiStateTest)
    }
}
