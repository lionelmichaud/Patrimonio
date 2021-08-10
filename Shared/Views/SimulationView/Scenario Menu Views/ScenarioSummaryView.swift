//
//  ScenarioHeaderView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import EconomyModel
import SocioEconomyModel
import ModelEnvironment
import Persistence
import AssetsModel
import PersonModel

/// Affiche des valeures des modèles utilisées pour le dernier Run de simulation
struct ScenarioSummaryView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var family     : Family

    var body: some View {
        VStack {
            Text("Derniers paramètres de simulation utilisés").bold()
            Form {
                Section(header: Text("Modèle Humain")) {
                    ForEach(family.members.items) { member in
                        if let adult = member as? Adult {
                            Text(adult.displayName)
                            VStack {
                                LabeledText(label: "Age de décès",
                                            text : "\(adult.ageOfDeath) ans en \(String(adult.yearOfDeath))")
                                    .padding(.leading)
                                LabeledText(label: "Nombre d'années de dépendance",
                                            text : "\(adult.nbOfYearOfDependency) ans à partir de \(String(adult.ageOfDependency)) ans en \(adult.yearOfDependency)")
                                    .padding(.leading)
                            }
                        }
                    }
                }
                Section(header: Text("Modèle Economique")) {
                    PercentView(label   : "Inflation",
                                percent : model.economyModel.randomizers.inflation.value(withMode: simulation.mode)/100.0)
                    PercentView(label   : "Rendement annuel moyen des Obligations sans risque",
                                percent : model.economyModel.randomizers.securedRate.value(withMode: simulation.mode)/100.0)
                    if UserSettings.shared.simulateVolatility {
                        PercentView(label   : "Volatilité des Obligations sans risque",
                                    percent : model.economyModel.randomizers.securedVolatility/100.0)
                    }
                    PercentView(label   : "Rendement annuel moyen des Actions",
                                percent : model.economyModel.randomizers.stockRate.value(withMode: simulation.mode)/100.0)
                    if UserSettings.shared.simulateVolatility {
                        PercentView(label   : "Volatilité des Actions",
                                    percent : model.economyModel.randomizers.stockVolatility/100.0)
                    }
                }
                Section(header: Text("Modèle Sociologique")) {
                    PercentView(label   : "Dévaluation anuelle des pensions par rapport à l'inflation",
                                percent : -model.socioEconomyModel.pensionDevaluationRate.value(withMode: simulation.mode)/100.0)
                    IntegerView(label   : "Nombre de trimestres additionels pour obtenir le taux plein",
                                integer : Int(model.socioEconomyModel.nbTrimTauxPlein.value(withMode: simulation.mode)))
                    PercentView(label   : "Pénalisation des dépenses",
                                percent : model.socioEconomyModel.expensesUnderEvaluationRate.value(withMode: simulation.mode)/100.0)
                }
            }
            .navigationTitle("Résumé")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: { })
            .onDisappear(perform: { })
        }
    }
}

struct ScenarioSummaryViewView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
            ScenarioSummaryView()
                .environmentObject(uiState)
                .environmentObject(family)
                .environmentObject(patrimoine)
                .environmentObject(simulation)
                .previewLayout(.sizeThatFits)
    }
}
