//
//  KpiView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import LifeExpense
import PatrimoineModel

struct KpiSectionView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var isKpiExpanded  : Bool = false
    
    var body: some View {
        if simulation.isComputed {
            Section(header: Text("Performance")) {
                // synthèse des KPIs
                DisclosureGroup(isExpanded: $isKpiExpanded,
                                content: {
                                    NavigationLink(destination : KpiListSummaryView(),
                                                   tag         : .kpiSummaryView,
                                                   selection   : $uiState.simulationViewState.selectedItem) {
                                        HStack {
                                            if let allObjectivesAreReached = simulation.kpis.allObjectivesAreReached(withMode: simulation.mode) {
                                                Image(systemName: allObjectivesAreReached ? "checkmark.circle.fill" : "multiply.circle.fill")
                                                    .imageScale(.medium)
                                                    .foregroundColor(allObjectivesAreReached ? .green : .red)
                                            }
                                            Text("Synthèse")
                                        }
                                    }
                                    .isDetailLink(true)
                                    
                                    // Liste des KPIs
                                    KpiListView()
                                },
                                label: {
                                    Text("Indicateurs")//.font(.headline)
                                })
                
                // Résultats tabulés des runs de MontéCarlo
                GridsView()
            }
        }
    }
}

struct KpiView_Previews: PreviewProvider {
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var family     = Family()
    static var expenses   = LifeExpensesDic()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        simulation.compute(using          : model,
                           nbOfYears      : 40,
                           nbOfRuns       : 1,
                           withFamily     : family,
                           withExpenses   : expenses,
                           withPatrimoine : patrimoine)
        return
            NavigationView {
                List {KpiSectionView()
                    .environmentObject(uiState)
                    .environmentObject(family)
                    .environmentObject(patrimoine)
                    .environmentObject(simulation)}
            }
    }
}
