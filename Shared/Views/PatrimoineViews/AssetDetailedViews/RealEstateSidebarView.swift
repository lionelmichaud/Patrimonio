//
//  RealEstateSidebarView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 01/04/2022.
//

import SwiftUI
import AppFoundation
import AssetsModel
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct RealEstateSidebarView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    private let indentLevel = 1
    private let label       = "Immeuble"
    private let iconAdd     = Image(systemName : "plus.circle.fill")
    private let icon€       = Image(systemName   : "eurosign.circle.fill")

    var body: some View {
        Group {
            // label
            LabeledValueRowView(colapse     : $uiState.patrimoineViewState.assetViewState.colapseEstate,
                                label       : "Immeuble",
                                value       : patrimoine.assets.realEstates.currentValue,
                                indentLevel : 2,
                                header      : true)
            if !uiState.patrimoineViewState.assetViewState.colapseEstate {
                // ajout d'un nouvel item à la liste
                NavigationLink(destination : RealEstateDetailedView(item      : nil,
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
                ForEach(patrimoine.assets.realEstates.items) { item in
                    NavigationLink(destination: RealEstateDetailedView(item       : item,
                                                                       family     : family,
                                                                       patrimoine : patrimoine)) {
                        LabeledValueRowView(colapse     : self.$uiState.patrimoineViewState.assetViewState.colapseEstate,
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

