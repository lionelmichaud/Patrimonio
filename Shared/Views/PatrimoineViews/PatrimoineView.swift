//
//  AssetListView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Persistence
import PatrimoineModel
import FamilyModel

struct PatrimoineView: View {
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var dataStore  : Store
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        NavigationView {
            /// Primary view
            List {
                // entête
                PatrimoineHeaderView()
                
                if dataStore.activeDossier != nil {
                    Button("Réinitialiser",
                           action: reinitialize)
                        //.capsuleButtonStyle()
                        .disabled(dataStore.activeDossier!.folder == nil)
                    
                    PatrimoineTotalView()
                    
                    // actifs
                    AssetView()
                    
                    // passifs
                    LiabilityView()
                }
            }
            .defaultSideBarListStyle()
            //.listStyle(GroupedListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .navigationTitle("Patrimoine")
            .toolbar {
                EditButton()
            }

            /// vue par défaut
            PatrimoineSummaryView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
    private func reinitialize() {
        do {
            try self.patrimoine.loadFromJSON(fromFolder: dataStore.activeDossier!.folder!)
            uiState.patrimoineViewState.evalDate = Date.now.year.double()
        } catch {
            self.alertItem = AlertItem(title         : Text("Le chargement a échoué"),
                                       dismissButton : .default(Text("OK")))
            
        }
    }
}

struct PatrimoineTotalView: View {
    @EnvironmentObject private var patrimoine : Patrimoin

    var body: some View {
        Section {
            HStack {
                Text("Actif Net")
                    .font(Font.system(size: 17,
                                      design: Font.Design.default))
                    .fontWeight(.bold)
                Spacer()
                Text(patrimoine.value(atEndOf: Date.now.year).€String)
                    .font(Font.system(size: 17,
                                      design: Font.Design.default))
            }
            .listRowBackground(ListTheme.rowsBaseColor)
        }
    }
}

struct PatrimoineHeaderView: View {
    @EnvironmentObject var patrimoine: Patrimoin
    
    var body: some View {
        Section {
            NavigationLink(destination: PatrimoineSummaryView()) {
                Text("Résumé").fontWeight(.bold)
            }.isDetailLink(true)
            }
    }
}

struct AssetListView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()

    static var previews: some View {
        PatrimoineView()
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
        //.colorScheme(.dark)
    }
}
