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
    let simulationReseter: CanResetSimulationP
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
                RealEstateSidebarView(simulationReseter: simulationReseter)
                ScpiSidebarView(simulationReseter: simulationReseter)
            } label: {
                LabeledValueRowView(label       : "Immobilier",
                                     value       : totalImmobilier,
                                     indentLevel : indentLevel + 1,
                                     header      : true,
                                     iconItem    : nil)
            }

            /// Financier
            DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandFinancier) {
                PeriodicInvestSidebarView(simulationReseter: simulationReseter)
                FreeInvestSidebarView(simulationReseter: simulationReseter)
            } label: {
                LabeledValueRowView(label       : "Financier",
                                     value       : totalFinancier,
                                     indentLevel : indentLevel + 1,
                                     header      : true,
                                     iconItem    : nil)
            }

            /// SCI
            DisclosureGroup(isExpanded: $uiState.patrimoineViewState.assetViewState.expandSCI) {
                SciScpiSidebarView(simulationReseter: simulationReseter)
            } label: {
                LabeledValueRowView(label       : "SCI",
                                     value       : totalSCI,
                                     indentLevel : indentLevel + 1,
                                     header      : true,
                                     iconItem    : nil)
            }
        } label: {
            LabeledValueRowView(label       : label,
                                 value       : netAsset,
                                 indentLevel : indentLevel,
                                 header      : true,
                                 iconItem    : nil)
        }
    }
}

struct AssetView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromTemplate()
        return Group {
            NavigationView {
                List {
                    AssetSidebarView(simulationReseter: TestEnvir.simulation)
                        .environmentObject(TestEnvir.family)
                        .environmentObject(TestEnvir.patrimoine)
                        .environmentObject(TestEnvir.uiState)
                }
                EmptyView()
            }
            .colorScheme(.dark)
            .previewDisplayName("AssetView")

            NavigationView {
                List {
                    AssetSidebarView(simulationReseter: TestEnvir.simulation)
                        .environmentObject(TestEnvir.family)
                        .environmentObject(TestEnvir.patrimoine)
                        .environmentObject(TestEnvir.uiState)
                }
                EmptyView()
            }
            .colorScheme(.light)
            .previewDisplayName("AssetView")
        }
    }
}
