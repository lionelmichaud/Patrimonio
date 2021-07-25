//
//  SimulationView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct SimulationView: View {
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
                ComputationSectionView()
                
                if dataStore.activeDossier != nil {
                    // affichage du scénario utilisé pour la simulation
                    ScenarioSectionView()
                    
                    // affichage des résultats des KPIs
                    KpiSectionView()
                    
                    // affichage des résultats graphiques
                    ChartsSectionView()
                    
                    // affichage des autres résultats
                    SuccessionsSectionView()
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

struct SimulationView_Previews: PreviewProvider {
    static var model      = Model(fromBundle: Bundle.main)
    static let dataStore  = Store()
    static var uiState    = UIState()
    static var family     = try! Family(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var patrimoine = try! Patrimoin(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var simulation = Simulation()

    static var previews: some View {
        simulation.compute(using          : model,
                           nbOfYears      : 5,
                           nbOfRuns       : 1,
                           withFamily     : family,
                           withPatrimoine : patrimoine)
        return
            SimulationView()
            .environmentObject(dataStore)
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
