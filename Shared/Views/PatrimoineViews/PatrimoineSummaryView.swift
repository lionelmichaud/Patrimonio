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
                            Image(systemName: "square.and.arrow.up")
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

    func share(geometry: GeometryProxy) {
        var urls = [URL]()
        do {
            // vérifier l'existence du Folder associé au Dossier
            guard let activeFolder = dataStore.activeDossier!.folder else {
                throw DossierError.failedToFindFolder
            }
            
            // collecte des URL des fichiers contenus dans le dossier
            activeFolder.files.forEach { file in
                if file.name.contains("FreeInvestement") ||
                    file.name.contains("SCPI") ||
                    file.name.contains("PeriodicInvestement") ||
                    file.name.contains("RealEstateAsset") ||
                    file.name.contains("Debt") ||
                    file.name.contains("Loan") {
                    urls.append(file.url)
                }
            }
            
        } catch {
            self.alertItem = AlertItem(title         : Text((error as! DossierError).rawValue),
                                       dismissButton : .default(Text("OK")))
        }
        
        // partage des fichiers collectés
        let sideBarWidth = 230.0
        Patrimonio.share(items: urls, fromX: Double(geometry.size.width) + sideBarWidth, fromY: 32.0)
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
