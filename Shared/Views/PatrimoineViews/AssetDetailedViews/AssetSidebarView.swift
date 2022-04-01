//
//  AssetView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct AssetSidebarView: View {
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var patrimoine : Patrimoin
    private let indentLevel = 0
    private let label = "Actif"

    private var netAsset: Double {
        patrimoine.assets.value(atEndOf: CalendarCst.thisYear)
    }

    private var totalImmobilier: Double {
        patrimoine.assets.realEstates.value(atEndOf: CalendarCst.thisYear) +
        patrimoine.assets.scpis.value(atEndOf: CalendarCst.thisYear)
    }

    private var totalFinancier: Double {
        patrimoine.assets.periodicInvests.value(atEndOf: CalendarCst.thisYear) +
        patrimoine.assets.freeInvests.value(atEndOf: CalendarCst.thisYear)
    }

    private var totalSCI: Double {
        patrimoine.assets.sci.scpis.value(atEndOf: CalendarCst.thisYear) +
        patrimoine.assets.sci.bankAccount
    }

    var body: some View {
        DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandAsset) {
            /// Immobilier
            DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandImmobilier) {
                //RealEstateSidebarView()
                ScpiSidebarView()
            } label: {
                LabeledValueRowView2(label       : "Immobilier",
                                     value       : totalImmobilier,
                                     indentLevel : indentLevel + 1,
                                     header      : true,
                                     iconItem    : nil)
            }

            /// Financier
            DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandFinancier) {
                Text("Financier")
//                PeriodicInvestView()
//                FreeInvestView()
            } label: {
                LabeledValueRowView2(label       : "Financier",
                                     value       : totalFinancier,
                                     indentLevel : indentLevel + 1,
                                     header      : true,
                                     iconItem    : nil)
            }

            /// SCI
            DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandSCI) {
                SciScpiSidebarView()
            } label: {
                LabeledValueRowView2(label       : "SCI",
                                     value       : totalSCI,
                                     indentLevel : indentLevel + 1,
                                     header      : true,
                                     iconItem    : nil)
            }
        } label: {
            LabeledValueRowView2(label       : label,
                                 value       : netAsset,
                                 indentLevel : indentLevel,
                                 header      : true,
                                 iconItem    : nil)
        }
    }
}

struct PeriodicInvestView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()

        patrimoine.assets.periodicInvests.delete(at: offsets)
    }

    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.periodicInvests.move(from: source, to: destination)
    }

    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.expandPeriodic,
                                label       : "Invest Périodique",
                                value       : patrimoine.assets.periodicInvests.value(atEndOf: CalendarCst.thisYear),
                                indentLevel : 2,
                                header      : true)
            // items
            if !uiState.patrimoineViewState.assetViewState.expandPeriodic {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: PeriodicInvestDetailedView(item       : nil,
                                                                       family     : family,
                                                                       patrimoine : patrimoine)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.periodicInvests.items) { item in
                    NavigationLink(destination: PeriodicInvestDetailedView(item       : item,
                                                                           family     : family,
                                                                           patrimoine : self.patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.expandPeriodic,
                                            label       : item.name,
                                            value       : item.value(atEndOf: CalendarCst.thisYear),
                                            indentLevel : 3,
                                            header      : false,
                                            icon        : Image(systemName: "eurosign.circle.fill"))
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct FreeInvestView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()

        patrimoine.assets.freeInvests.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.freeInvests.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.expandFree,
                                label       : "Investissement Libre",
                                value       : patrimoine.assets.freeInvests.value(atEndOf: CalendarCst.thisYear),
                                indentLevel : 2,
                                header      : true)
            
            // items
            if !uiState.patrimoineViewState.assetViewState.expandFree {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: FreeInvestDetailedView(item       : nil,
                                                                   family     : family,
                                                                   patrimoine : patrimoine)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.freeInvests.items) { item in
                    NavigationLink(destination: FreeInvestDetailedView(item       : item,
                                                                       family     : family,
                                                                       patrimoine : self.patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.expandFree,
                                            label       : item.name,
                                            value       : item.value(atEndOf: CalendarCst.thisYear),
                                            indentLevel : 3,
                                            header      : false,
                                            icon        : Image(systemName: "eurosign.circle.fill"))
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
        }
    }
}

struct AssetView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    static var uiState    = UIState()

    static var previews: some View {
        return
            Group {
                    NavigationView {
                        List {
                        AssetSidebarView()
                            .environmentObject(family)
                            .environmentObject(patrimoine)
                            .environmentObject(simulation)
                            .environmentObject(uiState)
                        }
                }
                    .colorScheme(.dark)
                    .previewDisplayName("AssetView")

                NavigationView {
                    List {
                        AssetSidebarView()
                            .environmentObject(family)
                            .environmentObject(patrimoine)
                            .environmentObject(simulation)
                            .environmentObject(uiState)
                    }
                }
                    .colorScheme(.light)
                    .previewDisplayName("AssetView")
            }
    }
}
