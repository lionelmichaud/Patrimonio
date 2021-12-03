//
//  ModelEconomyView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import EconomyModel
import ModelEnvironment
import Persistence
import Statistics

/// Affiche un graphique des fonctions de distribution des modèles statistiques
struct ModelEconomyView: View {
    @EnvironmentObject private var model : Model
    @State private var modelChoice       : Economy.RandomVariable = .inflation

    var body: some View {
        VStack {
            // sélecteur: inflation / securedRate / stockRate
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            
            switch modelChoice {
                case .inflation:
                    BetaRandomizerEditView(with: model.economyModel.randomizers.inflation) { viewModel in
                        viewModel.update(&model.economyModel.randomizers.inflation)
                        model.economy.persistenceSM.process(event: .onModify)
                    }
                    applyChangesToModelClone: { viewModel, clone in
                        viewModel.update(&clone.economyModel.randomizers.inflation)
                    }

                case .securedRate:
                    BetaRandomizerEditView(with: model.economyModel.randomizers.securedRate) { viewModel in
                        viewModel.update(&model.economyModel.randomizers.securedRate)
                        model.economy.persistenceSM.process(event: .onModify)
                    }
                    applyChangesToModelClone: { viewModel, clone in
                        viewModel.update(&clone.economyModel.randomizers.securedRate)
                    }

                case .stockRate:
                    BetaRandomizerEditView(with: model.economyModel.randomizers.stockRate) { viewModel in
                        viewModel.update(&model.economyModel.randomizers.stockRate)
                        model.economy.persistenceSM.process(event: .onModify)
                    }
                    applyChangesToModelClone: { viewModel, clone in
                        viewModel.update(&clone.economyModel.randomizers.stockRate)
                    }
            }
        }
        .navigationTitle("Modèle Economique")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelEconomyView()
    }
}
