//
//  LiabilityView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Liabilities
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct LiabilitySidebarView: View {
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    
    var body: some View {
        Section {
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.liabViewState.colapseLiab,
                                label       : "Passif",
                                value       : patrimoine.liabilities.value(atEndOf: CalendarCst.thisYear),
                                indentLevel : 0,
                                header      : true)

            if !uiState.patrimoineViewState.liabViewState.colapseLiab {
                    LoanSidebarView()
                    DebtSidebarView()
            }
        }
    }
}

struct LoanSidebarView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    func removeItems(at offsets: IndexSet) {
        patrimoine.liabilities.loans.delete(at: offsets)
        
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()
    }
    
    func move(from source: IndexSet, to destination: Int) {
        patrimoine.liabilities.loans.move(from: source, to: destination)
    }
    
    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.liabViewState.colapseEmpruntlist,
                                label       : "Emprunt",
                                value       : patrimoine.liabilities.loans.value(atEndOf: CalendarCst.thisYear),
                                indentLevel : 1,
                                header      : true)
            
            // items
            if !uiState.patrimoineViewState.liabViewState.colapseEmpruntlist {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination: LoanDetailedView(item       : nil,
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
                ForEach(patrimoine.liabilities.loans.items) { item in
                    NavigationLink(destination: LoanDetailedView(item       : item,
                                                                 family     : family,
                                                                 patrimoine : self.patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.liabViewState.colapseEmpruntlist,
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

struct DebtSidebarView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    var body: some View {
        ScrollViewReader { proxy in
            Section {
                // label
                LabeledValueRowView(colapse     : $uiState.patrimoineViewState.liabViewState.colapseDetteListe,
                                    label       : "Dette",
                                    value       : patrimoine.liabilities.debts.value(atEndOf: CalendarCst.thisYear),
                                    indentLevel : 1,
                                    header      : true)

                // items
                if !uiState.patrimoineViewState.liabViewState.colapseDetteListe {
                    // ajout d'un nouvel item à la liste
                    Button(
                        action: { addItem(proxy: proxy) },
                        label: {
                            Label(title: { Text("Ajouter un élément...") },
                                  icon : { Image(systemName: "plus.circle.fill").imageScale(.large) })
                        })

                    // liste des items
                    ForEach($patrimoine.liabilities.debts.items) { $item in
                        NavigationLink(destination: DebtDetailedView2(updateDependenciesToModel: resetSimulation,
                                                                      item: $item.transaction())) {
                            LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.liabViewState.colapseDetteListe,
                                                label       : item.name,
                                                value       : item.value(atEndOf: CalendarCst.thisYear),
                                                indentLevel : 3,
                                                header      : false,
                                                icon        : Image(systemName: "eurosign.circle.fill"))
                        }
                                                                      .isDetailLink(true)
                                                                      .id(item.id)
                    }
                    .onDelete(perform: removeItems)
                    .onMove(perform: move)
                }
            }
        }
    }

    /// actualiser toutes les dépendances au Model
    private func resetSimulation() {
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()
    }

    func removeItems(at offsets: IndexSet) {
        patrimoine.liabilities.debts.delete(at: offsets)

        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()
    }

    func move(from source: IndexSet, to destination: Int) {
        patrimoine.liabilities.debts.move(from: source, to: destination)
    }

    func addItem(proxy: ScrollViewProxy) {
        // ajouter un nouvel item ) la liste
        let newItem = Debt(name: "Nouvel élément",
                           delegateForAgeOf: family.ageOf)
        // réinitialiser la simulation
        patrimoine.liabilities.debts.add(newItem)
        // scroller jusqu'au nouvel item
        proxy.scrollTo(newItem.id, anchor: .bottom)
        resetSimulation()
    }
}

struct LiabilityView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    static var uiState    = UIState()

    static var previews: some View {
        NavigationView {
            List {
                LiabilitySidebarView()
                    .environmentObject(family)
                    .environmentObject(patrimoine)
                    .environmentObject(simulation)
                    .environmentObject(uiState)
                    .previewDisplayName("LiabilityView")
            }
        }
    }
}
