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
import HelpersView
import SimulationAndVisitors

// MARK: - Deterministic SocioEconomy View

struct ModelDeterministicSociologyView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    let updateDependenciesToModel: ( ) -> Void
    @State private var alertItem : AlertItem?
    
    var body: some View {
        Form {
            Section(header: Text("Dévaluation des pensions").font(.headline)) {
                VersionEditableViewInForm(version: $model.socioEconomyModel.pensionDevaluationRate.version)

                Stepper(value : $model.socioEconomyModel.pensionDevaluationRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Évolution anuelle des pensions de retraite")
                        Spacer()
                        Text("\(model.socioEconomyModel.pensionDevaluationRate.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.socioEconomyModel.pensionDevaluationRate) { _ in
                    updateDependenciesToModel()
                }
            }
            
            Section(header: Text("Évolution du nombre de trimestres requis").font(.headline)) {
                VersionEditableViewInForm(version: $model.socioEconomyModel.nbTrimTauxPlein.version)

                Stepper(value : $model.socioEconomyModel.nbTrimTauxPlein.defaultValue,
                        in    : 0 ... 12) {
                    HStack {
                        Text("Nombre de trimestres additionels pour obtenir le taux plein")
                        Spacer()
                        Text("\(Int(model.socioEconomyModel.nbTrimTauxPlein.defaultValue)) ans")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.socioEconomyModel.nbTrimTauxPlein) { _ in
                    updateDependenciesToModel()
                }
            }
            
            Section(header: Text("Sous-estimation du niveau des dépenses").font(.headline)) {
                VersionEditableViewInForm(version: $model.socioEconomyModel.expensesUnderEvaluationRate.version)
                
                Stepper(value : $model.socioEconomyModel.expensesUnderEvaluationRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Pénalisation des dépenses")
                        Spacer()
                        Text("\(model.socioEconomyModel.expensesUnderEvaluationRate.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.socioEconomyModel.expensesUnderEvaluationRate) { _ in
                    updateDependenciesToModel()
                }
            }
        }
        .navigationTitle("Modèle Sociologique")
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

struct ModelDeterministicSociologyView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelDeterministicSociologyView(updateDependenciesToModel: { })
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
            .preferredColorScheme(.dark)
    }
}
