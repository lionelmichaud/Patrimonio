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
    @State private var alertItem         : AlertItem?

    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())

            switch modelChoice {
                case .pensionDevaluationRate:
                    BetaRandomizerEditView(with: model.socioEconomyModel.pensionDevaluationRate) { viewModel in
                        viewModel.update(&model.socioEconomyModel.pensionDevaluationRate)
                        model.socioEconomy.persistenceSM.process(event: .onModify)
                    }
                    onSaveToTemplate : { viewModel in
                        applyChangesToTemplate(from: viewModel)
                    }

                case .nbTrimTauxPlein:
                    EmptyView()
                    DiscreteRandomizerView(randomizer: model.socioEconomyModel.nbTrimTauxPlein)

                case .expensesUnderEvaluationRate:
                    BetaRandomizerEditView(with: model.socioEconomyModel.expensesUnderEvaluationRate) { viewModel in
                        viewModel.update(&model.socioEconomyModel.expensesUnderEvaluationRate)
                        model.socioEconomy.persistenceSM.process(event: .onModify)
                    }
                    onSaveToTemplate : { viewModel in
                        applyChangesToTemplate(from: viewModel)
                    }
            }
        }
        .navigationTitle("Modèle Sociologique: Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Methods
    
    /// Enregistrer la modification dans le répertoire Template (sur disque)
    func applyChangesToTemplate(from viewModel: BetaRandomViewModel) {
        guard let templateFolder = PersistenceManager.templateFolder() else {
            alertItem =
                AlertItem(title         : Text("Echec"),
                          dismissButton : .default(Text("OK")))
            return
        }
        
        viewModel.update(&model.socioEconomyModel.pensionDevaluationRate)
        viewModel.update(&model.socioEconomyModel.expensesUnderEvaluationRate)
        model.socioEconomy.persistenceSM.process(event: .onModify)

        do {
            try model.saveAsJSON(toFolder: templateFolder)
        } catch {
            alertItem =
                AlertItem(title         : Text("Echec"),
                          dismissButton : .default(Text("OK")))
        }
    }
}

struct ModelSociologyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSociologyView()
    }
}
