//
//  ModelFiscalIrppView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel
import SimulationAndVisitors
import HelpersView

struct ModelFiscalIrppView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    @State private var showingSheet = false
    
    var body: some View {
        Form {
            VersionEditableViewInForm(version: $model.fiscalModel.incomeTaxes.model.version)
                .onChange(of: model.fiscalModel.incomeTaxes.model.version) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

            Section(header: Text("Salaire").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême IRPP",
                                                         grid: $model.fiscalModel.incomeTaxes.model.grid)
                                .environmentObject(model)) {
                    Text("Barême")
                }.isDetailLink(true)
                
                Stepper(value : $model.fiscalModel.incomeTaxes.model.salaryRebate,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(model.fiscalModel.incomeTaxes.model.salaryRebate.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.incomeTaxes.model.salaryRebate) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                AmountEditView(label  : "Abattement minimum",
                               amount : $model.fiscalModel.incomeTaxes.model.minSalaryRebate)
                    .onChange(of: model.fiscalModel.incomeTaxes.model.minSalaryRebate) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }

                AmountEditView(label  : "Abattement maximum",
                               amount : $model.fiscalModel.incomeTaxes.model.maxSalaryRebate)
                    .onChange(of: model.fiscalModel.incomeTaxes.model.maxSalaryRebate) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }

                AmountEditView(label  : "Plafond de Réduction d'Impôt par Enfant",
                               amount : $model.fiscalModel.incomeTaxes.model.childRebate)
                    .onChange(of: model.fiscalModel.incomeTaxes.model.childRebate) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            Section(header: Text("BNC").font(.headline)) {
                Stepper(value : $model.fiscalModel.incomeTaxes.model.turnOverRebate,
                        in    : 0 ... 100.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(model.fiscalModel.incomeTaxes.model.turnOverRebate.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.incomeTaxes.model.turnOverRebate) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                AmountEditView(label  : "Abattement minimum",
                               amount : $model.fiscalModel.incomeTaxes.model.minTurnOverRebate)
                    .onChange(of: model.fiscalModel.incomeTaxes.model.minTurnOverRebate) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
        }
        .navigationTitle("Revenus du Travail")
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

struct ModelFiscalIrppView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelFiscalIrppView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
            .preferredColorScheme(.dark)
    }
}
