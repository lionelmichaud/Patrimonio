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
import SimulationAndVisitors
import HelpersView

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
                VersionEditableViewInForm(version: $model.economyModel.randomizers.inflation.version)

                Stepper(value : $model.economyModel.randomizers.inflation.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Inflation")
                        Spacer()
                        Text("\(model.economyModel.randomizers.inflation.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Placements sans Risque").font(.headline)) {
                VersionEditableViewInForm(version: $model.economyModel.randomizers.securedRate.version)

                Stepper(value : $model.economyModel.randomizers.securedRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(model.economyModel.randomizers.securedRate.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $model.economyModel.randomizers.securedVolatility,
                        in    : 0 ... 5,
                        step  : 0.1) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(model.economyModel.randomizers.securedVolatility.percentString(digit: 2))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Placements Actions").font(.headline)) {
                VersionEditableViewInForm(version: $model.economyModel.randomizers.stockRate.version)

                Stepper(value : $model.economyModel.randomizers.stockRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.05) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(model.economyModel.randomizers.stockRate.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $model.economyModel.randomizers.stockVolatility,
                        in    : 0 ... 20,
                        step  : 1.0) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(model.economyModel.randomizers.stockVolatility.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: model.economyModel.randomizers) { _ in
            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
            model.manageInternalDependencies()
        }
        .navigationTitle("Modèle Economique")
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

struct ModelDeterministicEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelDeterministicEconomyView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
            .preferredColorScheme(.dark)
    }
}
