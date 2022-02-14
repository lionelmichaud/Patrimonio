//
//  ModelHumanView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import HumanLifeModel
import ModelEnvironment
import FamilyModel
import Persistence

struct ModelHumanView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem   : AlertItem?
    @State private var modelChoice: HumanLife.RandomVariable = .menLifeExpectation
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            
            switch modelChoice {
                case .menLifeExpectation:
                    DiscreteRandomizerEditView(discreteRandomizer: $model.humanLifeModel.menLifeExpectation)
                        .onChange(of: model.humanLifeModel.menLifeExpectation) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }

                case .womenLifeExpectation:
                    DiscreteRandomizerEditView(discreteRandomizer: $model.humanLifeModel.womenLifeExpectation)
                        .onChange(of: model.humanLifeModel.womenLifeExpectation) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }

                case .nbOfYearsOfdependency:
                    DiscreteRandomizerEditView(discreteRandomizer: $model.humanLifeModel.nbOfYearsOfdependency)
                        .onChange(of: model.humanLifeModel.nbOfYearsOfdependency) { _ in
                            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                            model.manageInternalDependencies()
                        }
            }
        }
        .navigationTitle("Modèle Humain")
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

struct ModelHumanView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelHumanView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
