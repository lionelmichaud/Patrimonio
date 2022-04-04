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
import HelpersView

/// Affiche un graphique des fonctions de distribution des modèles statistiques
struct ModelStatisticSociologyView: View {
    let updateDependenciesToModel: ( ) -> Void
    @EnvironmentObject private var model: Model
    @State private var modelChoice : SocioEconomy.RandomVariable = .pensionDevaluationRate
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            
            // éditeur + graphique
            switch modelChoice {
                case .pensionDevaluationRate:
                    BetaRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                           betaRandomizer: $model.socioEconomyModel.randomizers.pensionDevaluationRate.transaction()) //{ viewModel in

                case .nbTrimTauxPlein:
                    DiscreteRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                               discreteRandomizer: $model.socioEconomyModel.randomizers.nbTrimTauxPlein.transaction())

                case .expensesUnderEvaluationRate:
                    BetaRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                           betaRandomizer: $model.socioEconomyModel.randomizers.expensesUnderEvaluationRate.transaction()) //{ viewModel in
            }
        }
        .navigationTitle("Modèle Sociologique")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelSociologyView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelStatisticSociologyView(updateDependenciesToModel: { })
            .environmentObject(TestEnvir.model)
            .preferredColorScheme(.dark)
    }
}
