//
//  ContentView.swift
//  Shared
//
//  Created by Lionel MICHAUD on 18/04/2021.
//

import SwiftUI

// TODO: - décommenter les lignes commentées
struct ContentView: View {

    // MARK: - Environment Properties

    @EnvironmentObject private var uiState: UIState
    //@SceneStorage("selectedTab") var selection = UIState.Tab.family

    // MARK: - Properties

    var body: some View {
        NavigationView {
            List(selection: $uiState.selectedSideBarItem) {
                /// composition de la famille
                //            FamilyView()
                NavigationLink(
                    destination: AppVersionView(),
                    tag: UIState.Tab.family,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Famille", systemImage: "person.2.fill")
                }
                .tag(UIState.Tab.family)

                /// dépenses de la famille
                //            ExpenseView()
                NavigationLink(
                    destination: AppVersionView(),
                    tag: UIState.Tab.expense,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Dépenses", systemImage: "cart.fill")
                }
                .tag(UIState.Tab.expense)

                /// actifs & passifs du patrimoine de la famille
                //            PatrimoineView()
                NavigationLink(
                    destination: AppVersionView(),
                    tag: UIState.Tab.asset,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Patrimoine", systemImage: "dollarsign.circle.fill")
                }
                .tag(UIState.Tab.asset)

                /// scenario paramètrique de simulation
                //            ScenarioView()
                NavigationLink(
                    destination: AppVersionView(),
                    tag: UIState.Tab.scenario,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Scénarios", systemImage: "slider.horizontal.3")
                }
                .tag(UIState.Tab.scenario)

                /// calcul et présentation des résultats de simulation
                //            SimulationView()
                NavigationLink(
                    destination: AppVersionView(),
                    tag: UIState.Tab.simulation,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Simulation", systemImage: "function")
                }
                .tag(UIState.Tab.simulation)
            }
        }
        .frame(minWidth: 150)
        .listStyle(SidebarListStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
