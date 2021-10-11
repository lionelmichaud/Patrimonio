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

struct GraphicUserSettings: View {
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    // si la variable d'état est locale (@State) cela ne fonctionne pas correctement
    @Binding var ownership         : OwnershipNature
    @Binding var evaluatedFraction : EvaluatedFraction
    
    var body: some View {
        Form {
            Section(header: Text("Graphique Bilan".uppercased()),
                footer: Text("Le graphique détaillé de l'évolution dans le temps du bilan d'un individu ne prendra en compte que les biens satisfaisant à ce critère")) {
                CasePicker(pickedCase: $ownership, label: "Filtrage des actifs et passifs du Bilan individuel")
                    .pickerStyle(DefaultPickerStyle())
                    .onChange(of     : ownership,
                              perform: { newValue in
                                UserSettings.shared.ownershipGraphicSelection = newValue
                              })
            }
            
            Section(footer: Text("Le graphique détaillé de l'évolution dans le temps du bilan d'un individu prendra en compte cette valorisation")) {
                CasePicker(pickedCase: $evaluatedFraction, label: "Valorisation d'un bien dans un bilan individuel")
                    .pickerStyle(DefaultPickerStyle())
                    .onChange(of     : evaluatedFraction,
                              perform: { newValue in
                                UserSettings.shared.assetGraphicEvaluatedFraction = newValue
                              })
            }
        }
    }
}

struct GraphicUserSettings_Previews: PreviewProvider {
    static var family  = Family()
    static var patrimoine = Patrimoin()

    static func ageOf(_ name: String, _ year: Int) -> Int {
        let person = family.member(withName: name)
        return person?.age(atEndOf: Date.now.year) ?? -1
    }
    
    static var previews: some View {
        NavigationView {
            NavigationLink(destination: GraphicUserSettings(ownership         : .constant(.all),
                                                            evaluatedFraction : .constant(.totalValue))
                            .environmentObject(patrimoine)) {
                Label("Graphiques", systemImage: "chart.bar.xaxis")
            }
        }
    }
}
