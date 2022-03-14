//
//  SwiftUIView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import Persistence
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct FamilySidebarView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    @State var showingSheet = false
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // entête
                FamilyHeaderView()
                
                if dataStore.activeDossier != nil {
                    // liste des membres de la famille
                    FamilySectionView(showingSheet: $showingSheet)
                }
            }
            //.defaultSideBarListStyle()
            .listStyle(SidebarListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Famille")
            .toolbar {
                EditButton()
            }
            
            /// vue par défaut
            FamilySummaryView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        // Vue modale de saisie d'un nouveau membre de la famille
        .sheet(isPresented: $showingSheet) {
            PersonAddView(using: model)
                .environmentObject(self.model)
                .environmentObject(self.family)
                .environmentObject(self.simulation)
                .environmentObject(self.patrimoine)
                .environmentObject(self.uiState)
        }
    }
}

struct FamilyHeaderView: View {
    var body: some View {
        NavigationLink(destination: FamilySummaryView()) {
            Text("Synthèse").fontWeight(.bold)
        }
        .isDetailLink(true)
    }
}

struct FamilyView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return FamilySidebarView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.uiState)
            .colorScheme(.dark)
        //.previewLayout(.fixed(width: 1024, height: 768))
        //.previewLayout(.fixed(width: 896, height: 414))
        //.previewDevice(PreviewDevice(rawValue: "iPad Air (3rd generation)"))
        //.previewLayout(.sizeThatFits)
        //.environment(\.colorScheme, .dark)
        //.environment(\.colorScheme, .light)
        //.environment(\.locale, .init(identifier: "fr"))
    }
}
