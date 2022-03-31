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
    @EnvironmentObject var patrimoine : Patrimoin
    private let indentLevel = 0
    private let label = "Actif"

    var body: some View {
        Section {
            // immobilier
            LabeledValueRowView2(label       : "Immobilier",
                                 value       : patrimoine.assets.realEstates.value(atEndOf: CalendarCst.thisYear) +
                                 patrimoine.assets.scpis.value(atEndOf: CalendarCst.thisYear),
                                 indentLevel : 1,
                                 header      : true,
                                 iconItem    : nil)
            RealEstateSidebarView()
            //ScpiView()

            // financier
//            LabeledValueRowView(label       : "Financier",
//                                value       : patrimoine.assets.periodicInvests.value(atEndOf: CalendarCst.thisYear) +
//                                patrimoine.assets.freeInvests.value(atEndOf: CalendarCst.thisYear),
//                                indentLevel : 1,
//                                header      : true)
//            PeriodicInvestView()
//            FreeInvestView()

            // SCI
//            LabeledValueRowView(label       : "SCI",
//                                value       : patrimoine.assets.sci.scpis.value(atEndOf: CalendarCst.thisYear) +
//                                patrimoine.assets.sci.bankAccount,
//                                indentLevel : 1,
//                                header      : true)
//            SciScpiView()
        } header: {
            LabeledValueRowView2(label       : label,
                                 value       : patrimoine.assets.value(atEndOf: CalendarCst.thisYear),
                                 indentLevel : 0,
                                 header      : true,
                                 iconItem    : nil)
        }
    }
}

struct ScpiView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()

        patrimoine.assets.scpis.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.scpis.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseSCPI,
                                label       : "SCPI",
                                value       : patrimoine.assets.scpis.currentValue,
                                indentLevel : 2,
                                header      : true)
            // items
            if !uiState.patrimoineViewState.assetViewState.colapseSCPI {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: ScpiDetailedView(item       : nil,
                                                             //family     : self.family,
                                                             updateItem : { (localItem, index) in
                                                                self.patrimoine.assets.scpis.update(with: localItem, at: index) },
                                                             addItem    : { (localItem) in
                                                                self.patrimoine.assets.scpis.add(localItem) },
                                                             family     : family,
                                                             firstIndex : { (localItem) in
                                                                self.patrimoine.assets.scpis.items.firstIndex(of: localItem) })) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.scpis.items) { item in
                    NavigationLink(destination: ScpiDetailedView(item       : item,
                                                                 //family     : self.family,
                                                                 updateItem : { (localItem, index) in
                                                                    self.patrimoine.assets.scpis.update(with: localItem, at: index) },
                                                                 addItem    : { (localItem) in
                                                                    self.patrimoine.assets.scpis.add(localItem) },
                                                                 family     : family,
                                                                 firstIndex : { (localItem) in
                                                                    self.patrimoine.assets.scpis.items.firstIndex(of: localItem) })) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapseSCPI,
                                            label       : item.name,
                                            value       : item.value(atEndOf: CalendarCst.thisYear),
                                            indentLevel : 3,
                                            header      : false,
                                            icon        : Image(systemName: "building.2.crop.circle"))
                    }
                    .isDetailLink(true)
                }
                .onDelete(perform: removeItems)
                .onMove(perform: move)
            }
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
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapsePeriodic,
                                label       : "Invest Périodique",
                                value       : patrimoine.assets.periodicInvests.value(atEndOf: CalendarCst.thisYear),
                                indentLevel : 2,
                                header      : true)
            // items
            if !uiState.patrimoineViewState.assetViewState.colapsePeriodic {
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
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapsePeriodic,
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
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseFree,
                                label       : "Investissement Libre",
                                value       : patrimoine.assets.freeInvests.value(atEndOf: CalendarCst.thisYear),
                                indentLevel : 2,
                                header      : true)
            
            // items
            if !uiState.patrimoineViewState.assetViewState.colapseFree {
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
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapseFree,
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

struct SciScpiView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()

        patrimoine.assets.sci.scpis.delete(at: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.assets.sci.scpis.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseSCISCPI,
                                label       : "SCPI",
                                value       : patrimoine.assets.sci.scpis.currentValue,
                                indentLevel : 2,
                                header      : true)
            // items
            if !uiState.patrimoineViewState.assetViewState.colapseSCISCPI {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: ScpiDetailedView(item       : nil,
                                                             //patrimoine : patrimoine,
                                                             updateItem : { (localItem, index) in
                                                                self.patrimoine.assets.sci.scpis.update(with: localItem, at: index) },
                                                             addItem    : { (localItem) in
                                                                self.patrimoine.assets.sci.scpis.add(localItem) },
                                                             family     : family,
                                                             firstIndex : { (localItem) in
                                                                self.patrimoine.assets.sci.scpis.items.firstIndex(of: localItem) })) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                        Text("Ajouter un élément...")
                    }
                    .foregroundColor(.accentColor)
                }
                
                // liste des items
                ForEach(patrimoine.assets.sci.scpis.items) { item in
                    NavigationLink(destination: ScpiDetailedView(item: item,
                                                                 //patrimoine : patrimoine,
                                                                 updateItem : { (localItem, index) in
                                                                    self.patrimoine.assets.sci.scpis.update(with: localItem, at: index) },
                                                                 addItem    : { (localItem) in
                                                                    self.patrimoine.assets.sci.scpis.add(localItem) },
                                                                 family     : family,
                                                                 firstIndex : { (localItem) in
                                                                    self.patrimoine.assets.sci.scpis.items.firstIndex(of: localItem) })) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapseSCISCPI,
                                            label       : item.name,
                                            value       : item.value(atEndOf: CalendarCst.thisYear),
                                            indentLevel : 3,
                                            header      : false,
                                            icon        : Image(systemName: "building.2.crop.circle"))
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
