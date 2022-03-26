//
//  ChartsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import LifeExpense
import PatrimoineModel
import SimulationAndVisitors
import FamilyModel

struct ChartsSidebarSectionView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var isBsExpanded   : Bool = false
    @State private var isCfExpanded   : Bool = false
    @State private var isIrppExpanded : Bool = false
    @State private var isIsfExpanded  : Bool = false

    var body: some View {
        if simulation.isComputed {
            Section(header: Text("Graphiques") ) {
                DisclosureGroup(isExpanded: $isBsExpanded,
                                content: {
                                    NavigationLink(destination : BalanceSheetGlobalChartView(),
                                                   tag         : .bilanSynthese,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Synthèse de l'évolution")
                                    }
                                    .isDetailLink(true)
                                    
                                    NavigationLink(destination : BalanceSheetDetailedChartView(),
                                                   tag         : .bilanDetail,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Détails de l'évolution")
                                    }
                                    .isDetailLink(true)
                                },
                                label: {
                                    Label("Bilan", systemImage: "chart.bar.xaxis")
                                })

                DisclosureGroup(isExpanded: $isCfExpanded,
                                content: {
                                    NavigationLink(destination : CashFlowGlobalChartView(),
                                                   tag         : .cfSynthese,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Synthèse de l'évolution")
                                    }
                                    .isDetailLink(true)
                                    
                                    NavigationLink(destination : CashFlowDetailedChartView(),
                                                   tag         : .cfDetail,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Détails de l'évolution")
                                    }
                                    .isDetailLink(true)
                                },
                                label: {
                                    Label("Cash Flow", systemImage: "chart.bar.xaxis")
                                })

                DisclosureGroup(isExpanded: $isIrppExpanded,
                                content: {
                                    NavigationLink(destination : IrppEvolutionChartView(),
                                                   tag         : .irppSynthesis,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Synthèse de l'évolution")
                                    }
                                    .isDetailLink(true)
                                    
                                    NavigationLink(destination : IrppSliceView(),
                                                   tag         : .irppSlices,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Décomposition par tranche")
                                    }
                                    .isDetailLink(true)
                                },
                                label: {
                                    Label("Impôt sur le Revenu", systemImage: "chart.bar.xaxis")
                                })

                DisclosureGroup(isExpanded: $isIsfExpanded,
                                content: {
                                    NavigationLink(destination : IsfEvolutionChartView(),
                                                   tag         : .isfSynthesis,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        Text("Synthèse de l'évolution")
                                    }
                                    .isDetailLink(true)
                                },
                                label: {
                                    Label("Impôt sur la Fortune", systemImage: "chart.bar.xaxis")
                                })
            }
        } else {
            EmptyView()
        }
    }
}

struct ChartsSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        TestEnvir.simulation.compute(using          : TestEnvir.model,
                               nbOfYears      : 5,
                               nbOfRuns       : 1,
                               withFamily     : TestEnvir.family,
                               withExpenses   : TestEnvir.expenses,
                               withPatrimoine : TestEnvir.patrimoine)
        return NavigationView {
            List {
                ChartsSidebarSectionView()
                    .environmentObject(TestEnvir.uiState)
                    .environmentObject(TestEnvir.family)
                    .environmentObject(TestEnvir.patrimoine)
                    .environmentObject(TestEnvir.simulation)
            }
        }
    }
}
