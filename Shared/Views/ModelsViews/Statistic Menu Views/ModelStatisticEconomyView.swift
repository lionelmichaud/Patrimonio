//
//  ModelEconomyView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import EconomyModel
import HelpersView

/// Affiche un graphique des fonctions de distribution des modèles statistiques
struct ModelStatisticEconomyView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Binding var subModel: Economy.RandomizersModel
    @State private var modelChoice : Economy.RandomVariable = .inflation

    var body: some View {
        VStack(alignment: .leading) {
            // sélecteur: inflation / securedRate / stockRate
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(.segmented)

            // éditeur + graphique
            switch modelChoice {
                case .inflation:
                    BetaRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                           betaRandomizer: $subModel.inflation.transaction()) //{ viewModel in

                case .securedRate:
                    BetaRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                           betaRandomizer: $subModel.securedRate.transaction()) //{ viewModel in

                case .stockRate:
                    BetaRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                           betaRandomizer: $subModel.stockRate.transaction()) //{ viewModel in
            }
        }
        .navigationTitle("Modèle Economique")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelStatisticEconomyView(updateDependenciesToModel: { },
                                  subModel: .constant(TestEnvir.model.economy.model!.randomizers))
        .preferredColorScheme(.dark)
    }
}
