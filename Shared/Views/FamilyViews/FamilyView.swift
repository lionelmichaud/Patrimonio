//
//  SwiftUIView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct FamilyView: View {
    @EnvironmentObject private var dataStore  : Store
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
            PersonAddView()
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
            Text("Résumé").fontWeight(.bold)
        }
        .isDetailLink(true)
    }
}

struct FamilyView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static let family     = Family()
    static let simulation = Simulation()
    static let patrimoine = Patrimoin()
    static let uiState    = UIState()
    
    static var previews: some View {
        FamilyView()
            .environmentObject(dataStore)
            .environmentObject(family)
            .environmentObject(simulation)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
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
