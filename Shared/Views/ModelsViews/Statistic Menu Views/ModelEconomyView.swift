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

/// Affiche un graphique des fonctions de distribution des modèles statistiques
struct ModelEconomyView: View {
    @EnvironmentObject private var model  : Model
    @State private var modelChoice: Economy.RandomVariable = .inflation
    
    var body: some View {
        VStack {
            // sélecteur: inflation / securedRate / stockRate
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            switch modelChoice {
                case .inflation:
                    BetaRandomizerView(randomizer: model.economyModel.randomizers.inflation)

                case .securedRate:
                    BetaRandomizerView(randomizer: model.economyModel.randomizers.securedRate)

                case .stockRate:
                    BetaRandomizerView(randomizer: model.economyModel.randomizers.stockRate)
            }
        }
        .navigationTitle("Modèle Economique: Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelEconomyView()
    }
}
