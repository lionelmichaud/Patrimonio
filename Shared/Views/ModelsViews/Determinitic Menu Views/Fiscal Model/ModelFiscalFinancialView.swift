//
//  ModelFiscalFinancialView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalFinancialView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $model.fiscalModel.financialRevenuTaxes.model.version)
                .onChange(of: model.fiscalModel.financialRevenuTaxes.model.version) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

            Section(footer: Text("Appliquable à tous les revenus financiers")) {
                Stepper(value : $model.fiscalModel.financialRevenuTaxes.model.CRDS,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CRDS")
                        Spacer()
                        Text("\(model.fiscalModel.financialRevenuTaxes.model.CRDS.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.financialRevenuTaxes.model.CRDS) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.fiscalModel.financialRevenuTaxes.model.CSG,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CSG")
                        Spacer()
                        Text("\(model.fiscalModel.financialRevenuTaxes.model.CSG.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.financialRevenuTaxes.model.CSG) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.fiscalModel.financialRevenuTaxes.model.prelevSocial,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Prélèvement Sociaux")
                        Spacer()
                        Text("\(model.fiscalModel.financialRevenuTaxes.model.prelevSocial.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.financialRevenuTaxes.model.prelevSocial) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
        }
        .navigationTitle("Revenus Financiers")
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

struct ModelFiscalFinancialView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelFiscalFinancialView()
            .preferredColorScheme(.dark)
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
