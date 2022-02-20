//
//  PatrimoineSummaryView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import SwiftUI
import AppFoundation
import Persistence

struct PatrimoineSummaryView: View {
    @EnvironmentObject private var dataStore : Store
    @EnvironmentObject private var uiState   : UIState
    @State private var alertItem: AlertItem?
    @State private var presentation = "Table"
    let minDate = CalendarCst.thisYear
    let maxDate = CalendarCst.thisYear + 55
    
    var body: some View {
        if dataStore.activeDossier != nil {
            GeometryReader { geometry in
                VStack {
                    // évaluation annuelle du patrimoine
                    HStack {
                        Text("Evaluation fin ") + Text(String(Int(uiState.patrimoineViewState.evalDate)))
                        Slider(value : $uiState.patrimoineViewState.evalDate,
                               in    : minDate.double() ... maxDate.double(),
                               step  : 1,
                               onEditingChanged: {_ in
                        })
                    }
                    .padding(.horizontal)

                    if presentation == "Table" {
                        // vue tabulaire
                        PatrimoineSummaryTableView()
                    } else if presentation == "ShareChart" {
                        // vue graphique
                        PatrimoineSummaryShareChartView()
                    } else if presentation == "RiskChart" {
                        PatrimoineSummaryRiskChartView()
                    }
                }
                .navigationTitle("Synthèse")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Picker("Présentation", selection: $presentation) {
                            Image(systemName: "tablecells").tag("Table")
                            Image(systemName: "chart.pie").tag("ShareChart")
                            Image(systemName: "exclamationmark.triangle").tag("RiskChart")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    /// bouton Exporter fichiers du dossier actif
                    ToolbarItem(placement: .automatic) {
                        Button(action: { share(geometry: geometry) },
                               label: {
                            Image(systemName: "square.and.arrow.up.on.square")
                                .imageScale(.large)
                        })
                            .capsuleButtonStyle()
                    }
                }
            }
            .alert(item: $alertItem, content: newAlert)
        } else {
            NoLoadedDossierView()
        }
    }

    private func share(geometry: GeometryProxy) {
        // collecte des URL des fichiers contenus dans le dossier
        let fileNameKeys = ["FreeInvestement",
                            "PeriodicInvestement",
                            "RealEstateAsset",
                            "SCPI",
                            "Debt",
                            "Loan"]
        shareFiles(dataStore: dataStore,
                   fileNames: fileNameKeys,
                   alertItem: &alertItem,
                   geometry: geometry)
    }
}

struct PatrimoineSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return PatrimoineSummaryView()
            .environmentObject(dataStoreTest)
            .environmentObject(familyTest)
            .environmentObject(patrimoineTest)
            .environmentObject(uiStateTest)
    }
}
