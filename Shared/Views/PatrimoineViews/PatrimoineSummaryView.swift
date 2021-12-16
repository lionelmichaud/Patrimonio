//
//  PatrimoineSummaryView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import SwiftUI
import AppFoundation
import Persistence
import PatrimoineModel
import FamilyModel

struct PatrimoineSummaryView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
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
                
                Form {
                    Section(header: header("", year: Int(uiState.patrimoineViewState.evalDate))) {
                        HStack {
                            Text("Actif Net").fontWeight(.bold)
                            Spacer()
                            Text(patrimoine.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)).€String)
                        }
                    }
                    .listRowBackground(ListTheme.rowsBaseColor)
                    
                    Section(header: header("ACTIF", year: Int(uiState.patrimoineViewState.evalDate))) {
                        Group {
                            // (0) Immobilier
                            ListTableRowView(label       : "Immobilier",
                                             value       : patrimoine.assets.realEstates.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)) +
                                                patrimoine.assets.scpis.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)),
                                             indentLevel : 0,
                                             header      : true)
                            //      (1) Immeuble
                            ListTableRowView(label       : "Immeuble",
                                             value       : patrimoine.assets.realEstates.currentValue,
                                             indentLevel : 1,
                                             header      : true)
                            ForEach(patrimoine.assets.realEstates.items) { item in
                                ListTableRowView(label       : item.name,
                                                 value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                                 indentLevel : 2,
                                                 header      : false)
                            }
                            //      (1) SCPI
                            ListTableRowView(label       : "SCPI",
                                             value       : patrimoine.assets.scpis.currentValue,
                                             indentLevel : 1,
                                             header      : true)
                            ForEach(patrimoine.assets.scpis.items) { item in
                                ListTableRowView(label       : item.name,
                                                 value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                                 indentLevel : 2,
                                                 header      : false)
                            }
                        }
                        
                        Group {
                            // (0) Financier
                            ListTableRowView(label       : "Financier",
                                             value       : patrimoine.assets.periodicInvests.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)) +
                                                patrimoine.assets.freeInvests.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)),
                                             indentLevel : 0,
                                             header      : true)
                            //      (1) Invest Périodique
                            ListTableRowView(label       : "Invest Périodique",
                                             value       : patrimoine.assets.periodicInvests.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)),
                                             indentLevel : 1,
                                             header      : true)
                            ForEach(patrimoine.assets.periodicInvests.items) { item in
                                ListTableRowView(label       : item.name,
                                                 value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                                 indentLevel : 2,
                                                 header      : false)
                            }
                            //      (1) Investissement Libre
                            ListTableRowView(label       : "Investissement Libre",
                                             value       : patrimoine.assets.freeInvests.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)),
                                             indentLevel : 1,
                                             header      : true)
                            ForEach(patrimoine.assets.freeInvests.items) { item in
                                ListTableRowView(label       : item.name,
                                                 value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                                 indentLevel : 2,
                                                 header      : false)
                            }
                        }
                        
                        Group {
                            // (0) SCI
                            ListTableRowView(label       : "SCI",
                                             value       : patrimoine.assets.sci.scpis.value(atEndOf       : Int(uiState.patrimoineViewState.evalDate)) +
                                                patrimoine.assets.sci.bankAccount,
                                             indentLevel : 0,
                                             header      : true)
                            //      (1) SCPI
                            ListTableRowView(label       : "SCPI",
                                             value       : patrimoine.assets.sci.scpis.value(atEndOf       : Int(uiState.patrimoineViewState.evalDate)),
                                             indentLevel : 1,
                                             header      : true)
                            ForEach(patrimoine.assets.sci.scpis.items) { item in
                                ListTableRowView(label       : item.name,
                                                 value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                                 indentLevel : 2,
                                                 header      : false)
                            }
                        }
                    }
                    
                    Section(header: header("PASSIF", year: Int(uiState.patrimoineViewState.evalDate))) {
                        Group {
                            // (0) Emprunts
                            ListTableRowView(label       : "Emprunt",
                                             value       : patrimoine.liabilities.loans.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)),
                                             indentLevel : 0,
                                             header      : true)
                            ForEach(patrimoine.liabilities.loans.items) { item in
                                ListTableRowView(label       : item.name,
                                                 value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                                 indentLevel : 2,
                                                 header      : false)
                            }
                        }
                        
                        Group {
                            // (0) Dettes
                            ListTableRowView(label       : "Dette",
                                             value       : patrimoine.liabilities.debts.value(atEndOf: Int(uiState.patrimoineViewState.evalDate)),
                                             indentLevel : 0,
                                             header      : true)
                            ForEach(patrimoine.liabilities.debts.items) { item in
                                ListTableRowView(label       : item.name,
                                                 value       : item.value(atEndOf: Int(self.uiState.patrimoineViewState.evalDate)),
                                                 indentLevel : 2,
                                                 header      : false)
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
                .navigationTitle("Résumé")
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            NoLoadedDossierView()
        }
    }
    
    func header(_ trailingString: String, year: Int) -> some View {
        HStack {
            Text(trailingString)
            Spacer()
            Text("valorisation à fin \(year)")
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
