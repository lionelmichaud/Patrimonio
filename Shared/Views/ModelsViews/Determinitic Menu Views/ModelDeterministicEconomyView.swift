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
    @StateObject private var viewModel        : DeterministicViewModel
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Stepper(value : $viewModel.inflation,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Inflation")
                    Spacer()
                    Text("\(viewModel.inflation.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
            .onChange(of: viewModel.inflation) { _ in viewModel.isModified = true }
            
            Section(header: Text("Placements sans Risque").font(.headline)) {
                Stepper(value : $viewModel.securedRate,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(viewModel.securedRate.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.securedRate) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.securedVolatility,
                        in    : 0 ... 5,
                        step  : 0.1) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(viewModel.securedVolatility.percentString(digit: 2)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.securedVolatility) { _ in viewModel.isModified = true }
            }
            
            Section(header: Text("Placements Actions").font(.headline)) {
                Stepper(value : $viewModel.stockRate,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(viewModel.stockRate.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.stockRate) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.stockVolatility,
                        in    : 0 ... 20,
                        step  : 1.0) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(viewModel.stockVolatility.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: viewModel.stockVolatility) { _ in viewModel.isModified = true }
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

//struct ModelDeterministicEconomyView_Previews: PreviewProvider {
//    static var model = Model(fromBundle: Bundle.main)
//
//    static var previews: some View {
//        let viewModel = DeterministicViewModel(using: model)
//        return Form {
//            ModelDeterministicEconomyView()
//                .environmentObject(viewModel)
//        }
//        .preferredColorScheme(.dark)
//    }
//}
