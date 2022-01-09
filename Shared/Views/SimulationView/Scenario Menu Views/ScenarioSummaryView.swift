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
                                percent : model.economyModel.randomizers.inflation.value(withMode: simulationMode)/100.0)
                    PercentView(label   : "Rendement annuel moyen des Obligations sans risque",
                                percent : model.economyModel.randomizers.securedRate.value(withMode: simulationMode)/100.0)
                    if simulateVolatility {
                        PercentView(label   : "Volatilité des Obligations sans risque",
                                    percent : model.economyModel.randomizers.securedVolatility/100.0)
                    }
                    PercentView(label   : "Rendement annuel moyen des Actions",
                                percent : model.economyModel.randomizers.stockRate.value(withMode: simulationMode)/100.0)
                    if simulateVolatility {
                        PercentView(label   : "Volatilité des Actions",
                                    percent : model.economyModel.randomizers.stockVolatility/100.0)
                    }
                }

                // Modèle Sociologique
                Section(header: Text("Modèle Sociologique")) {
                    PercentView(label   : "Dévaluation anuelle des pensions par rapport à l'inflation",
                                percent : -model.socioEconomyModel.pensionDevaluationRate.value(withMode: simulationMode)/100.0)
                    IntegerView(label   : "Nombre de trimestres additionels pour obtenir le taux plein",
                                integer : Int(model.socioEconomyModel.nbTrimTauxPlein.value(withMode: simulationMode)))
                    PercentView(label   : "Pénalisation des dépenses",
                                percent : model.socioEconomyModel.expensesUnderEvaluationRate.value(withMode: simulationMode)/100.0)
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
