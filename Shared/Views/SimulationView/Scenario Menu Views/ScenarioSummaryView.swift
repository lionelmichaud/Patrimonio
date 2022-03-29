//
//  ScenarioSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Statistics
import EconomyModel
import SocioEconomyModel
import ModelEnvironment
import Persistence
import AssetsModel
import PersonModel
import FamilyModel
import HelpersView

/// Affiche des valeures des modèles utilisées pour le dernier Run de simulation
struct ScenarioSummaryView: View {
    var simulationMode : SimulationModeEnum
    @EnvironmentObject private var model  : Model
    @EnvironmentObject private var family : Family
    @Preference(\.simulateVolatility) var simulateVolatility

    var body: some View {
        VStack {
            Text("Derniers paramètres de simulation utilisés").bold()
            Form {
                // Modèle Humain
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

                // Modèle Economique
                Section(header: Text("Modèle Economique")) {
                    PercentView(label   : "Inflation",
                                percent : model.economyModel.randomizers.inflation.value(withMode: simulationMode))
                    PercentView(label   : "Rendement annuel moyen des Obligations sans risque",
                                percent : model.economyModel.randomizers.securedRate.value(withMode: simulationMode))
                    if simulateVolatility {
                        PercentView(label   : "Volatilité des Obligations sans risque",
                                    percent : model.economyModel.randomizers.securedVolatility)
                    }
                    PercentView(label   : "Rendement annuel moyen des Actions",
                                percent : model.economyModel.randomizers.stockRate.value(withMode: simulationMode))
                    if simulateVolatility {
                        PercentView(label   : "Volatilité des Actions",
                                    percent : model.economyModel.randomizers.stockVolatility)
                    }
                }

                // Modèle Sociologique
                Section(header: Text("Modèle Sociologique")) {
                    PercentView(label   : "Dévaluation anuelle des pensions par rapport à l'inflation",
                                percent : -model.socioEconomyModel.randomizers.pensionDevaluationRate.value(withMode: simulationMode))
                    IntegerView(label   : "Nombre de trimestres additionels pour obtenir le taux plein",
                                integer : Int(model.socioEconomyModel.randomizers.nbTrimTauxPlein.value(withMode: simulationMode)))
                    PercentView(label   : "Pénalisation des dépenses",
                                percent : model.socioEconomyModel.randomizers.expensesUnderEvaluationRate.value(withMode: simulationMode))
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
    static var model  = Model(fromBundle: Bundle.main)
    static var family = Family()

    static func initialize() {
        family = try! Family(fromBundle: Bundle.main, using: model)
    }

    static var previews: some View {
        initialize()
        return ScenarioSummaryView(simulationMode: .deterministic)
            .environmentObject(family)
            .environmentObject(model)
            .previewLayout(.sizeThatFits)
    }
}
