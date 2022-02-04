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
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @StateObject private var viewModel        : DeterministicViewModel
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Inflation").font(.headline)) {
                VersionEditableView(version: $viewModel.economyModel.randomizers.inflation.version)
                    .onChange(of: viewModel.economyModel.randomizers.inflation.version) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.economyModel.randomizers.inflation.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Inflation")
                        Spacer()
                        Text("\(viewModel.economyModel.randomizers.inflation.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                        .onChange(of: viewModel.economyModel.randomizers.inflation.defaultValue) { _ in viewModel.isModified = true }
            }

            Section(header: Text("Placements sans Risque").font(.headline)) {
                VersionEditableView(version: $viewModel.economyModel.randomizers.securedRate.version)
                    .onChange(of: viewModel.economyModel.randomizers.securedRate.version) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.economyModel.randomizers.securedRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(viewModel.economyModel.randomizers.securedRate.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.economyModel.randomizers.securedRate.defaultValue) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.economyModel.randomizers.securedVolatility,
                        in    : 0 ... 5,
                        step  : 0.1) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(viewModel.economyModel.randomizers.securedVolatility.percentString(digit: 2)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.economyModel.randomizers.securedVolatility) { _ in viewModel.isModified = true }
            }
            
            Section(header: Text("Placements Actions").font(.headline)) {
                VersionEditableView(version: $viewModel.economyModel.randomizers.stockRate.version)
                    .onChange(of: viewModel.economyModel.randomizers.stockRate.version) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.economyModel.randomizers.stockRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(viewModel.economyModel.randomizers.stockRate.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.economyModel.randomizers.stockRate.defaultValue) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.economyModel.randomizers.stockVolatility,
                        in    : 0 ... 20,
                        step  : 1.0) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(viewModel.economyModel.randomizers.stockVolatility.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.economyModel.randomizers.stockVolatility) { _ in viewModel.isModified = true }
            }
        }
        .navigationTitle("Modèle Economique")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    viewModel : viewModel,
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
            applyChangesToDossier: {
                alertItem = applyChangesToOpenDossierAlert(
                    viewModel  : viewModel,
                    model      : model,
                    family     : family,
                    simulation : simulation)
            },
            isModified: viewModel.isModified)
        .onAppear {
            viewModel.updateFrom(model)
        }
    }
    
    // MARK: - Initialization
    
    init(using model: Model) {
        _viewModel = StateObject(wrappedValue: DeterministicViewModel(using: model))
    }
}

struct ModelDeterministicEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelDeterministicEconomyView(using: modelTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
