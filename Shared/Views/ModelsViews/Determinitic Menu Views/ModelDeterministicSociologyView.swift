//
//  ModelDeterministicSociologyView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel

// MARK: - Deterministic SocioEconomy View

struct ModelDeterministicSociologyView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @StateObject private var viewModel        : DeterministicViewModel
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Stepper(value : $viewModel.socioEconomyModel.pensionDevaluationRate.defaultValue,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Dévaluation anuelle des pensions par rapport à l'inflation")
                    Spacer()
                    Text("\(viewModel.socioEconomyModel.pensionDevaluationRate.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.socioEconomyModel.pensionDevaluationRate.defaultValue) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.socioEconomyModel.nbTrimTauxPlein.defaultValue,
                    in    : 0 ... 12) {
                HStack {
                    Text("Nombre de trimestres additionels pour obtenir le taux plein")
                    Spacer()
                    Text("\(Int(viewModel.socioEconomyModel.nbTrimTauxPlein.defaultValue)) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.socioEconomyModel.nbTrimTauxPlein.defaultValue) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.socioEconomyModel.expensesUnderEvaluationRate.defaultValue,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Pénalisation des dépenses")
                    Spacer()
                    Text("\(viewModel.socioEconomyModel.expensesUnderEvaluationRate.defaultValue.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
                    .onChange(of: viewModel.socioEconomyModel.expensesUnderEvaluationRate.defaultValue) { _ in viewModel.isModified = true }
        }
        .navigationTitle("Modèle Sociologique")
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

//struct ModelDeterministicSociologyView_Previews: PreviewProvider {
//    static var model = Model(fromBundle: Bundle.main)
//    
//    static var previews: some View {
//        let viewModel = DeterministicViewModel(using: model)
//        return Form {
//            ModelDeterministicSociologyView()
//                .environmentObject(viewModel)
//        }
//        .preferredColorScheme(.dark)
//    }
//}
