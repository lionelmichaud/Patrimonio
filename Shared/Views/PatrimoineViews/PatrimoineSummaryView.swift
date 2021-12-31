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
    @State private var presentation = "Table"
    let minDate = CalendarCst.thisYear
    let maxDate = CalendarCst.thisYear + 55
    
    var body: some View {
        if dataStore.activeDossier != nil {
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
                } else {
                    // vue graphique
                    PatrimoineSummaryChartView()
                }
            }
            .navigationTitle("Résumé")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker("Présentation", selection: $presentation) {
                        Image(systemName: "tablecells").tag("Table")
                        Image(systemName: "chart.pie").tag("Chart")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
        } else {
            NoLoadedDossierView()
        }
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
