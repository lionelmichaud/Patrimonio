//
//  GraphicUserSettings.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI
import AppFoundation
import Ownership
import Persistence
import PatrimoineModel
import FamilyModel
import HelpersView
import SimulationAndVisitors

struct GraphicUserSettingsView: View {
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @Preference(\.ownershipGraphicSelection)     var ownershipGraphicSelection
    @Preference(\.assetGraphicEvaluatedFraction) var assetGraphicEvaluatedFraction

    var body: some View {
        Form {
            // Graphique Bilan
            Section {
                CasePicker(pickedCase: $ownershipGraphicSelection, label: "Filtrage des actifs et passifs du Bilan individuel")
                    .pickerStyle(DefaultPickerStyle())
                    .onChange(of: ownershipGraphicSelection) { newValue in
                        Preferences.standard.ownershipGraphicSelection = newValue
                    }
            } header: {
                Text("Graphique Bilan".uppercased())
            } footer: {
                Text("Le graphique détaillé de l'évolution dans le temps du bilan d'un individu ne prendra en compte que les biens satisfaisant à ce critère")
            }
            
            Section(footer: Text("Le graphique détaillé de l'évolution dans le temps du bilan d'un individu prendra en compte cette valorisation")) {
                CasePicker(pickedCase: $assetGraphicEvaluatedFraction, label: "Valorisation d'un bien dans un bilan individuel")
                    .pickerStyle(DefaultPickerStyle())
            }
        }
        .navigationTitle(Text("Graphiques"))
    }
}

struct GraphicUserSettings_Previews: PreviewProvider {
    static var family  = Family()
    static var patrimoine = Patrimoin()
    
    static func ageOf(_ name: String, _ year: Int) -> Int {
        let person = family.member(withName: name)
        return person?.age(atEndOf: CalendarCst.thisYear) ?? -1
    }
    
    static var previews: some View {
        NavigationView {
            NavigationLink(destination: GraphicUserSettingsView()
                            .environmentObject(patrimoine)) {
                Label("Graphiques", systemImage: "chart.bar.xaxis")
            }
        }
    }
}
