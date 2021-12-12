//
//  ContentView.swift
//  Shared
//
//  Created by Lionel MICHAUD on 18/04/2021.
//

import SwiftUI

struct ContentView: View {

    // MARK: - Environment Properties

    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var simulation : Simulation
    @SceneStorage("selectedTab") var selection = UIState.Tab.family

    // MARK: - Properties

    var body: some View {
        NavigationView {
            List(selection: $uiState.selectedSideBarItem) {
                /// composition de la famille
                NavigationLink(
                    destination: FamilySidebarView(),
                    tag: UIState.Tab.family,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Famille", systemImage: "person.2.fill")
                }
                .tag(UIState.Tab.family)

                /// dépenses de la famille
                NavigationLink(
                    destination: ExpenseSidebarView(simulationReseter: simulation),
                    tag: UIState.Tab.expense,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Dépenses", systemImage: "cart.fill")
                }
                .tag(UIState.Tab.expense)

                /// actifs & passifs du patrimoine de la famille
                NavigationLink(
                    destination: PatrimoineSidebarView(),
                    tag: UIState.Tab.asset,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Patrimoine", systemImage: "dollarsign.circle.fill")
                }
                .tag(UIState.Tab.asset)

                /// scenario paramètrique de simulation
                NavigationLink(
                    destination: ModelsSidebarView(),
                    tag: UIState.Tab.scenario,
                    selection: $uiState.selectedSideBarItem
                ) {
                    Label("Modèles", systemImage: "slider.horizontal.3")
                }
                .tag(UIState.Tab.scenario)

                /// calcul et présentation des résultats de simulation
                NavigationLink(
                    destination: SimulationSidebarView(),
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
    static let uiState    = UIState()
    static let simulation = Simulation()

    static var previews: some View {
        ContentView()
            .environmentObject(uiState)
            .environmentObject(simulation)
    }
}
