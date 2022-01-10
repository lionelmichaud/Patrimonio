//
//  ModelsSidebarView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import Persistence
import PatrimoineModel
import FamilyModel

struct ModelsSidebarView: View {
    @EnvironmentObject private var dataStore : Store
    @EnvironmentObject private var model     : Model
    @EnvironmentObject private var uiState   : UIState
    
    enum PushedItem {
        case deterministicModel, humanModel, economyModel, sociologyModel, statisticsAssistant
    }
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                if dataStore.activeDossier != nil {
                    // Modèle Déterministique
                    DeterministicSidebarSectionView()
                    
                    // Modèle Statistique
                    StatisticSidebarSectionView()
                    
                    // Assistant modèle statistique
                    RandomizerAssistantSidebarSectionView()
                } else {
                    Text("Modèles")
                }
            }
            //.defaultSideBarListStyle()
            .listStyle(SidebarListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Modèles")
            
            /// vue par défaut
            if dataStore.activeDossier != nil {
                ModelDeterministicView(using: model)
            } else {
                NoLoadedDossierView()
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct ModelsView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        dataStore.activate(dossierAtIndex: 0)
        return TabView {
            ModelsSidebarView()
                .tabItem { Label("Modèles", systemImage: "slider.horizontal.3") }
                .tag(UIState.Tab.scenario)
                .environmentObject(dataStore)
                .environmentObject(model)
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
        }
    }
}