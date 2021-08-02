//
//  ModelSociologyView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import SocioEconomyModel
import ModelEnvironment

struct ModelSociologyView: View {
    @EnvironmentObject private var model: Model
    @State private var modelChoice: SocioEconomy.RandomVariable = .pensionDevaluationRate
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())

            switch modelChoice {
                case .pensionDevaluationRate:
                    EmptyView()
                    BetaRandomizerView(randomizer: model.socioEconomyModel.pensionDevaluationRate)

                case .nbTrimTauxPlein:
                    EmptyView()
                    DiscreteRandomizerView(randomizer: model.socioEconomyModel.nbTrimTauxPlein)

                case .expensesUnderEvaluationRate:
                    BetaRandomizerView(randomizer: model.socioEconomyModel.expensesUnderEvaluationRate)
            }
        }
        .navigationTitle("Modèle Sociologique: Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelSociologyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSociologyView()
    }
}
