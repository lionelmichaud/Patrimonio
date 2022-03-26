//
//  ModelSociologyView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import SocioEconomyModel
import FamilyModel
import ModelEnvironment
import Persistence
import SimulationAndVisitors
import HelpersView

/// Affiche un graphique des fonctions de distribution des modèles statistiques
struct ModelStatisticSociologyView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem   : AlertItem?
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
                    BetaRandomizerEditView(betaRandomizer: $model.socioEconomyModel.pensionDevaluationRate) //{ viewModel in
                        .onChange(of: model.socioEconomyModel.pensionDevaluationRate) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }

                case .nbTrimTauxPlein:
                    DiscreteRandomizerEditView(discreteRandomizer: $model.socioEconomyModel.nbTrimTauxPlein)
                        .onChange(of: model.socioEconomyModel.nbTrimTauxPlein) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }

                case .expensesUnderEvaluationRate:
                    BetaRandomizerEditView(betaRandomizer: $model.socioEconomyModel.expensesUnderEvaluationRate) //{ viewModel in
                        .onChange(of: model.socioEconomyModel.expensesUnderEvaluationRate) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }
            }
        }
        .navigationTitle("Modèle Sociologique")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    model     : model,
                    notifyTemplatFolderMissing: {
                        DispatchQueue.main.async {
                            alertItem =
                            AlertItem(title         : Text("Répertoire 'Patron' absent"),
                                      dismissButton : .default(Text("OK")))
                        }
                    },
                    notifyFailure: {
                        DispatchQueue.main.async {
                            alertItem =
                            AlertItem(title         : Text("Echec de l'enregistrement"),
                                      dismissButton : .default(Text("OK")))
                        }
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

struct ModelSociologyView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelStatisticSociologyView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
            .preferredColorScheme(.dark)
    }
}
