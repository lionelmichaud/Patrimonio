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

/// Affiche un graphique des fonctions de distribution des modèles statistiques
struct ModelEconomyView: View {
    @EnvironmentObject private var model : Model
    @State private var modelChoice       : Economy.RandomVariable = .inflation
    @State private var alertItem         : AlertItem?

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
                    onSaveToTemplate : { viewModel in
                        applyChangesToTemplate(from: viewModel)
                    }

                case .securedRate:
                    BetaRandomizerEditView(with: model.economyModel.randomizers.securedRate) { viewModel in
                        viewModel.update(&model.economyModel.randomizers.securedRate)
                        model.economy.persistenceSM.process(event: .onModify)
                    }
                    onSaveToTemplate : { viewModel in
                        applyChangesToTemplate(from: viewModel)
                    }

                case .stockRate:
                    BetaRandomizerEditView(with: model.economyModel.randomizers.stockRate) { viewModel in
                        viewModel.update(&model.economyModel.randomizers.stockRate)
                        model.economy.persistenceSM.process(event: .onModify)
                    }
                    onSaveToTemplate : { viewModel in
                        applyChangesToTemplate(from: viewModel)
                    }
            }
        }
        .navigationTitle("Modèle Economique: Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $alertItem, content: myAlert)
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
        
        viewModel.update(&model.economyModel.randomizers.inflation)
        viewModel.update(&model.economyModel.randomizers.securedRate)
        viewModel.update(&model.economyModel.randomizers.stockRate)
        model.economy.persistenceSM.process(event: .onModify)

        do {
            try model.saveAsJSON(toFolder: templateFolder)
        } catch {
            alertItem =
                AlertItem(title         : Text("Echec"),
                          dismissButton : .default(Text("OK")))
        }
    }
}

struct ModelEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelEconomyView()
    }
}
