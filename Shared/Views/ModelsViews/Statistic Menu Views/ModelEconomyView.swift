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
    @EnvironmentObject private var model : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem         : AlertItem?
    @State private var modelChoice       : Economy.RandomVariable = .inflation

    var body: some View {
        VStack {
            // sélecteur: inflation / securedRate / stockRate
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            
            switch modelChoice {
                case .inflation:
                    HStack {
                        VersionEditableView(version: $model.economyModel.randomizers.inflation.version)
                            .onChange(of: model.economyModel.randomizers.inflation.version) { _ in
                                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                                model.manageInternalDependencies()
                            }
                        Spacer()
                    }
                    .frame(minHeight: 0, maxHeight: 100)
                    .padding(.horizontal)
                    BetaRandomizerEditView(with: model.economyModel.randomizers.inflation) { viewModel in
                        viewModel.update(&model.economyModel.randomizers.inflation)
                        model.economy.persistenceSM.process(event: .onModify)
                    }
                    applyChangesToModelClone: { viewModel, clone in
                        viewModel.update(&clone.economyModel.randomizers.inflation)
                    }
                    //.frame(minHeight: 0, maxHeight: .infinity)
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
