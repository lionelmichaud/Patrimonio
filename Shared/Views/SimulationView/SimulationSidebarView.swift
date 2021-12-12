//
//  SimulationView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel

struct SimulationSidebarView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    enum PushedItem {
        case lastScenarioUsed
        case computationView, bilanSynthese, bilanDetail, cfSynthese, cfDetail
        case kpiSummaryView, shortGridView
        case irppSynthesis, irppSlices, isfSynthesis, isfSlices
        case successionsLegal, successionsAssVie, successionCumul
    }
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // calcul de simulation
                ComputationSidebarSectionView()
                
                if dataStore.activeDossier != nil {
                    // affichage du scénario utilisé pour la simulation
                    ScenarioSidebarSectionView(simulationMode       : simulation.mode,
                                               simulationIsComputed : simulation.isComputed)
                    
                    // affichage des résultats des KPIs
                    KpiSidebarSectionView()
                    
                    // affichage des résultats graphiques
                    ChartsSidebarSectionView()
                    
                    // affichage des autres résultats
                    SuccessionsSidebarSectionView()
                }
            }
            //.defaultSideBarListStyle()
            .listStyle(SidebarListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Simulation")
            
            /// vue par défaut
            ComputationView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct SimulationSidebarView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        simulationTest.compute(using          : modelTest,
                               nbOfYears      : 5,
                               nbOfRuns       : 1,
                               withFamily     : familyTest,
                               withExpenses   : expensesTest,
                               withPatrimoine : patrimoineTest)
        return
            SimulationSidebarView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(uiStateTest)
            .environmentObject(familyTest)
            .environmentObject(expensesTest)
            .environmentObject(patrimoineTest)
            .environmentObject(simulationTest)
    }
}
