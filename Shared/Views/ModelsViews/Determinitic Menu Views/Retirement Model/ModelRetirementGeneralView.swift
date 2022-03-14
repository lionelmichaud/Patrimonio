//
//  ModelRetirementGeneralView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel
import HelpersView
import SimulationAndVisitors

// MARK: - Deterministic Retirement Régime General View

struct ModelRetirementGeneralView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $model.retirementModel.regimeGeneral.model.version)
                    .onChange(of: model.retirementModel.regimeGeneral.model.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            Stepper(value : $model.retirementModel.regimeGeneral.ageMinimumLegal,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum légal de liquidation")
                    Spacer()
                    Text("\(model.retirementModel.regimeGeneral.ageMinimumLegal) ans").foregroundColor(.secondary)
                }
            }
            .onChange(of: model.retirementModel.regimeGeneral.ageMinimumLegal) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            NavigationLink(destination: DureeRefGridView(label: "Durée de référence",
                                                         grid: $model.retirementModel.regimeGeneral.dureeDeReferenceGrid)
                            .environmentObject(model)) {
                Text("Durée de référence")
            }.isDetailLink(true)

            NavigationLink(destination: NbTrimUnemployementGridView(label: "Trimestres pour chômage non indemnisé",
                                                                    grid: $model.retirementModel.regimeGeneral.nbTrimNonIndemniseGrid)
                            .environmentObject(model)) {
                Text("Trimestres pour chômage non indemnisé")
            }.isDetailLink(true)

            Stepper(value : $model.retirementModel.regimeGeneral.maxReversionRate,
                    in    : 50 ... 100,
                    step  : 1.0) {
                HStack {
                    Text("Taux maximum")
                    Spacer()
                    Text("\(model.retirementModel.regimeGeneral.maxReversionRate.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.retirementModel.regimeGeneral.maxReversionRate) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            Section(header: Text("Décote / Surcote").font(.headline)) {
                Stepper(value : $model.retirementModel.regimeGeneral.decoteParTrimestre,
                        in    : 0 ... 1.5,
                        step  : 0.025) {
                    HStack {
                        Text("Décote par trimestre manquant")
                        Spacer()
                        Text("\(model.retirementModel.regimeGeneral.decoteParTrimestre.percentString(digit: 3))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.retirementModel.regimeGeneral.decoteParTrimestre) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.retirementModel.regimeGeneral.surcoteParTrimestre,
                        in    : 0 ... 2.5,
                        step  : 0.25) {
                    HStack {
                        Text("Surcote par trimestre supplémentaire")
                        Spacer()
                        Text("\(model.retirementModel.regimeGeneral.surcoteParTrimestre.percentString(digit: 2))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.retirementModel.regimeGeneral.surcoteParTrimestre) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.retirementModel.regimeGeneral.maxNbTrimestreDecote,
                        in    : 10 ... 30,
                        step  : 1) {
                    HStack {
                        Text("Nombre de trimestres maximum de décote")
                        Spacer()
                        Text("\(model.retirementModel.regimeGeneral.maxNbTrimestreDecote) trimestres")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.retirementModel.regimeGeneral.maxNbTrimestreDecote) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.retirementModel.regimeGeneral.majorationTauxEnfant,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour trois enfants nés")
                        Spacer()
                        Text("\(model.retirementModel.regimeGeneral.majorationTauxEnfant.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.retirementModel.regimeGeneral.majorationTauxEnfant) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
        }
        .navigationTitle("Régime Général")
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

struct ModelRetirementGeneralView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelRetirementGeneralView()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
