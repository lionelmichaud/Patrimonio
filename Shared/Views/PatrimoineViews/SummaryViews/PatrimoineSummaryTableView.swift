//
//  PatrimoineSummaryTableView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 30/12/2021.
//

import SwiftUI
import AssetsModel
import PatrimoineModel
import HelpersView
import ChartsExtensions

struct PatrimoineSummaryTableView: View {
    static let riskColors      = ChartThemes.riskColorsTable.map { Color($0) }
    static let liquidityColors = ChartThemes.liquidityColorsTable.map { Color($0) }
    static let riskLabel       = "Risque"
    static let liquidityLabel  = "Liquidité"

    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    
    var year: Int {
        Int(uiState.patrimoineViewState.evalDate)
    }
    
    var realEstateRiskView: some View {
        RatingView(rating    : patrimoine.assets.realEstates.items.averageRiskLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : RiskLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.riskLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.riskColors)
    }
    var realEstateLiquidityView: some View {
        RatingView(rating    : patrimoine.assets.realEstates.items.averageLiquidityLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : LiquidityLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.liquidityLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.liquidityColors)
    }
    var scpiRiskView: some View {
        RatingView(rating    : patrimoine.assets.scpis.items.averageRiskLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : RiskLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.riskLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.riskColors)
    }
    var scpiLiquidityView: some View {
        RatingView(rating    : patrimoine.assets.scpis.items.averageLiquidityLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : LiquidityLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.liquidityLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.liquidityColors)
    }
    var periodicRiskView: some View {
        RatingView(rating    : patrimoine.assets.periodicInvests.items.averageRiskLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : RiskLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.riskLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.riskColors)
    }
    var periodicLiquidityView: some View {
        RatingView(rating    : patrimoine.assets.periodicInvests.items.averageLiquidityLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : LiquidityLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.liquidityLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.liquidityColors)
    }
    var freeRiskView: some View {
        RatingView(rating    : patrimoine.assets.freeInvests.items.averageRiskLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : RiskLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.riskLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.riskColors)
    }
    var freeLiquidityView: some View {
        RatingView(rating    : patrimoine.assets.freeInvests.items.averageLiquidityLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : LiquidityLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.liquidityLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.liquidityColors)
    }
    var sciScpiRiskView: some View {
        RatingView(rating    : patrimoine.assets.sci.scpis.items.averageRiskLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : RiskLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.riskLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.riskColors)
    }
    var sciScpiLiquidityView: some View {
        RatingView(rating    : patrimoine.assets.sci.scpis.items.averageLiquidityLevel(atEndOf: year)?.rawValue ?? 0,
                   maxRating : LiquidityLevel.allCases.count - 1,
                   label     : PatrimoineSummaryTableView.liquidityLabel,
                   font      : .body,
                   onColor   : PatrimoineSummaryTableView.liquidityColors)
    }

    var body: some View {
        Form {
            Section(header: header("", year: year)) {
                HStack {
                    Text("Actif Net").fontWeight(.bold)
                    Spacer()
                    Text(patrimoine.value(atEndOf: year).€String)
                }
            }
            .listRowBackground(ListTheme.rowsBaseColor)
            
            Section(header: header("ACTIF", year: year)) {
                Group {
                    // (0) Immobilier
                    ListTableRowView(label       : "Immobilier",
                                     value       : patrimoine.assets.realEstates.value(atEndOf: year) +
                                        patrimoine.assets.scpis.value(atEndOf: year),
                                     indentLevel : 0,
                                     header      : true,
                                     rating1     : { EmptyView() },
                                     rating2     : { EmptyView() })
                    //      (1) Immeuble
                    ListTableRowView(label       : "Immeuble",
                                     value       : patrimoine.assets.realEstates.currentValue,
                                     indentLevel : 1,
                                     header      : true,
                                     rating1     : { realEstateRiskView },
                                     rating2     : { realEstateLiquidityView })
                    ForEach(patrimoine.assets.realEstates.items) { item in
                        ListTableRowView(label       : item.name,
                                         value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                         indentLevel : 2,
                                         header      : false,
                                         rating1: { RatingView(rating    : item.riskLevel?.rawValue ?? 0,
                                                               maxRating : RiskLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.riskLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.riskColors) },
                                         rating2: { RatingView(rating    : item.liquidityLevel?.rawValue ?? 0,
                                                               maxRating : LiquidityLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.liquidityLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.liquidityColors) })
                    }
                    //      (1) SCPI
                    ListTableRowView(label       : "SCPI",
                                     value       : patrimoine.assets.scpis.currentValue,
                                     indentLevel : 1,
                                     header      : true,
                                     rating1     : { scpiRiskView },
                                     rating2     : { scpiLiquidityView })
                    ForEach(patrimoine.assets.scpis.items) { item in
                        ListTableRowView(label       : item.name,
                                         value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                         indentLevel : 2,
                                         header      : false,
                                         rating1: { RatingView(rating    : item.riskLevel?.rawValue ?? 0,
                                                               maxRating : RiskLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.riskLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.riskColors) },
                                         rating2: { RatingView(rating    : item.liquidityLevel?.rawValue ?? 0,
                                                               maxRating : LiquidityLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.liquidityLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.liquidityColors) })
                    }
                }
                
                Group {
                    // (0) Financier
                    ListTableRowView(label       : "Financier",
                                     value       : patrimoine.assets.periodicInvests.value(atEndOf: year) +
                                        patrimoine.assets.freeInvests.value(atEndOf: year),
                                     indentLevel : 0,
                                     header      : true,
                                     rating1     : { EmptyView() },
                                     rating2     : { EmptyView() })
                    //      (1) Invest Périodique
                    ListTableRowView(label       : "Invest Périodique",
                                     value       : patrimoine.assets.periodicInvests.value(atEndOf: year),
                                     indentLevel : 1,
                                     header      : true,
                                     rating1     : { periodicRiskView },
                                     rating2     : { periodicLiquidityView })
                    ForEach(patrimoine.assets.periodicInvests.items) { item in
                        ListTableRowView(label       : item.name,
                                         value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                         indentLevel : 2,
                                         header      : false,
                                         rating1: { RatingView(rating    : item.riskLevel?.rawValue ?? 0,
                                                               maxRating : RiskLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.riskLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.riskColors) },
                                         rating2: { RatingView(rating    : item.liquidityLevel?.rawValue ?? 0,
                                                               maxRating : LiquidityLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.liquidityLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.liquidityColors) })
                        }
                                         //      (1) Investissement Libre
                    ListTableRowView(label       : "Investissement Libre",
                                     value       : patrimoine.assets.freeInvests.value(atEndOf: year),
                                     indentLevel : 1,
                                     header      : true,
                                     rating1     : { freeRiskView },
                                     rating2     : { freeLiquidityView })
                    ForEach(patrimoine.assets.freeInvests.items) { item in
                        ListTableRowView(label       : item.name,
                                         value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                         indentLevel : 2,
                                         header      : false,
                                         rating1: { RatingView(rating    : item.riskLevel?.rawValue ?? 0,
                                                               maxRating : RiskLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.riskLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.riskColors) },
                                         rating2: { RatingView(rating    : item.liquidityLevel?.rawValue ?? 0,
                                                               maxRating : LiquidityLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.liquidityLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.liquidityColors) })
                    }
                }
                
                Group {
                    // (0) SCI
                    ListTableRowView(label       : "SCI",
                                     value       : patrimoine.assets.sci.scpis.value(atEndOf: year) +
                                        patrimoine.assets.sci.bankAccount,
                                     indentLevel : 0,
                                     header      : true,
                                     rating1     : { sciScpiRiskView },
                                     rating2     : { sciScpiLiquidityView })
                    //      (1) SCPI
                    ListTableRowView(label       : "SCPI",
                                     value       : patrimoine.assets.sci.scpis.value(atEndOf: year),
                                     indentLevel : 1,
                                     header      : true,
                                     rating1     : { sciScpiRiskView },
                                     rating2     : { sciScpiLiquidityView })
                    ForEach(patrimoine.assets.sci.scpis.items) { item in
                        ListTableRowView(label       : item.name,
                                         value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                         indentLevel : 2,
                                         header      : false,
                                         rating1: { RatingView(rating    : item.riskLevel?.rawValue ?? 0,
                                                               maxRating : RiskLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.riskLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.riskColors) },
                                         rating2: { RatingView(rating    : item.liquidityLevel?.rawValue ?? 0,
                                                               maxRating : LiquidityLevel.allCases.count - 1,
                                                               label     : PatrimoineSummaryTableView.liquidityLabel,
                                                               font      : .callout,
                                                               onColor   : PatrimoineSummaryTableView.liquidityColors) })
                    }
                }
            }
            
            Section(header: header("PASSIF", year: year)) {
                Group {
                    // (0) Emprunts
                    ListTableRowView(label       : "Emprunt",
                                     value       : patrimoine.liabilities.loans.value(atEndOf: year),
                                     indentLevel : 0,
                                     header      : true,
                                     rating1     : { EmptyView() },
                                     rating2     : { EmptyView() })
                    ForEach(patrimoine.liabilities.loans.items) { item in
                        ListTableRowView(label       : item.name,
                                         value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                         indentLevel : 2,
                                         header      : false,
                                         rating1     : { EmptyView() },
                                         rating2     : { EmptyView() })
                    }
                }
                
                Group {
                    // (0) Dettes
                    ListTableRowView(label       : "Dette",
                                     value       : patrimoine.liabilities.debts.value(atEndOf: year),
                                     indentLevel : 0,
                                     header      : true,
                                     rating1     : { EmptyView() },
                                     rating2     : { EmptyView() })
                    ForEach(patrimoine.liabilities.debts.items) { item in
                        ListTableRowView(label       : item.name,
                                         value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                         indentLevel : 2,
                                         header      : false,
                                         rating1     : { EmptyView() },
                                         rating2     : { EmptyView() })
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
    
    func header(_ trailingString: String, year: Int) -> some View {
        HStack {
            Text(trailingString)
            Spacer()
            Text("valorisation à fin \(year)")
        }
    }
}

struct PatrimoineSummaryTableView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return PatrimoineSummaryTableView()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.uiState)
    }
}
