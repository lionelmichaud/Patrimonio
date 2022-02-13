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
import Persistence

struct ModelSociologyView: View {
    @EnvironmentObject private var model : Model
    @State private var modelChoice       : SocioEconomy.RandomVariable = .pensionDevaluationRate
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            
            switch modelChoice {
                case .pensionDevaluationRate:
                    BetaRandomizerEditView(betaRandomizer: $model.socioEconomyModel.pensionDevaluationRate) //{ viewModel in
//                        viewModel.update(&model.socioEconomyModel.pensionDevaluationRate)
//                        model.socioEconomy.persistenceSM.process(event: .onModify)
//                    }
//                    applyChangesToModelClone: { viewModel, clone in
//                        viewModel.update(&clone.socioEconomyModel.pensionDevaluationRate)
//                    }
                    
                case .nbTrimTauxPlein:
                    EmptyView()
                    DiscreteRandomizerView(randomizer: model.socioEconomyModel.nbTrimTauxPlein)
                    
                case .expensesUnderEvaluationRate:
                    BetaRandomizerEditView(betaRandomizer: $model.socioEconomyModel.expensesUnderEvaluationRate) //{ viewModel in
//                        viewModel.update(&model.socioEconomyModel.expensesUnderEvaluationRate)
//                        model.socioEconomy.persistenceSM.process(event: .onModify)
//                    }
//                    applyChangesToModelClone: { viewModel, clone in
//                        viewModel.update(&clone.socioEconomyModel.expensesUnderEvaluationRate)
//                    }
            }
        }
        .navigationTitle("Modèle Sociologique")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelSociologyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSociologyView()
    }
}
