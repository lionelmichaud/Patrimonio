//
//  ModelDeterministicEconomyModel.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel

// MARK: - Deterministic Economy View

struct ModelDeterministicEconomyView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            Section(header: Text("Inflation").font(.headline)) {
                VersionEditableView(version: $model.economyModel.randomizers.inflation.version)
                    .onChange(of: model.economyModel.randomizers.inflation.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
                
                Stepper(value : $model.economyModel.randomizers.inflation.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Inflation")
                        Spacer()
                        Text("\(model.economyModel.randomizers.inflation.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.economyModel.randomizers.inflation.defaultValue) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
            
            Section(header: Text("Placements sans Risque").font(.headline)) {
                VersionEditableView(version: $model.economyModel.randomizers.securedRate.version)
                    .onChange(of: model.economyModel.randomizers.securedRate.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
                
                Stepper(value : $model.economyModel.randomizers.securedRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(model.economyModel.randomizers.securedRate.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.economyModel.randomizers.securedRate.defaultValue) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
                
                Stepper(value : $model.economyModel.randomizers.securedVolatility,
                        in    : 0 ... 5,
                        step  : 0.1) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(model.economyModel.randomizers.securedVolatility.percentString(digit: 2)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.economyModel.randomizers.securedVolatility) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
            
            Section(header: Text("Placements Actions").font(.headline)) {
                VersionEditableView(version: $model.economyModel.randomizers.stockRate.version)
                    .onChange(of: model.economyModel.randomizers.stockRate.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
                
                Stepper(value : $model.economyModel.randomizers.stockRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(model.economyModel.randomizers.stockRate.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.economyModel.randomizers.stockRate.defaultValue) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
                
                Stepper(value : $model.economyModel.randomizers.stockVolatility,
                        in    : 0 ... 20,
                        step  : 1.0) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(model.economyModel.randomizers.stockVolatility.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.economyModel.randomizers.stockVolatility) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
        }
        .navigationTitle("Modèle Economique")
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

struct ModelDeterministicEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelDeterministicEconomyView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
