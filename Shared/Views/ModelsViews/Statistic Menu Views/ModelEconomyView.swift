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
import FamilyModel
import Persistence
import Statistics

/// Affiche un graphique des fonctions de distribution des modèles statistiques
struct ModelEconomyView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem   : AlertItem?
    @State private var modelChoice : Economy.RandomVariable = .inflation

    var body: some View {
        VStack(alignment: .leading) {
            // sélecteur: inflation / securedRate / stockRate
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())

            // éditeur + graphique
            switch modelChoice {
                case .inflation:
                    BetaRandomizerEditView(betaRandomizer: $model.economyModel.randomizers.inflation) //{ viewModel in
                        .onChange(of: model.economyModel.randomizers.inflation) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }
                case .securedRate:
                    BetaRandomizerEditView(betaRandomizer: $model.economyModel.randomizers.securedRate) //{ viewModel in
                        .onChange(of: model.economyModel.randomizers.securedRate) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }
                case .stockRate:
                    BetaRandomizerEditView(betaRandomizer: $model.economyModel.randomizers.stockRate) //{ viewModel in
                        .onChange(of: model.economyModel.randomizers.stockRate) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }
            }
        }
        .navigationTitle("Modèle Economique")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    model     : model,
                    notifyTemplatFolderMissing: {
                        alertItem =
                            AlertItem(title         : Text("Répertoire 'Patron' absent"),
                                      dismissButton : .default(Text("OK")))
                    },
                    notifyFailure: {
                        alertItem =
                            AlertItem(title         : Text("Echec de l'enregistrement"),
                                      dismissButton : .default(Text("OK")))
                    })
            },
            cancelChanges: {
                alertItem = cancelChanges(
                    to         : model,
                    family     : family,
                    simulation : simulation,
                    dataStore  : dataStore)
            },
            isModified: model.isModified)
    }
}

struct ModelEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelEconomyView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
