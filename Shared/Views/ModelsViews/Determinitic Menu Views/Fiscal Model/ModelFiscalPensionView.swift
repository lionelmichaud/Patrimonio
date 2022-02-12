//
//  ModelFiscalPensionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalPensionView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $model.fiscalModel.pensionTaxes.model.version)
                .onChange(of: model.fiscalModel.pensionTaxes.model.version) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

            Section(header: Text("Abattement").font(.headline)) {
                Stepper(value : $model.fiscalModel.pensionTaxes.model.rebate,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(model.fiscalModel.pensionTaxes.model.rebate.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.pensionTaxes.model.rebate) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                AmountEditView(label  : "Abattement minimum",
                               amount : $model.fiscalModel.pensionTaxes.model.minRebate)
                    .onChange(of: model.fiscalModel.pensionTaxes.model.minRebate) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }

                AmountEditView(label  : "Abattement maximum",
                               amount : $model.fiscalModel.pensionTaxes.model.maxRebate)
                    .onChange(of: model.fiscalModel.pensionTaxes.model.maxRebate) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            Section(header: Text("Taux de Cotisation").font(.headline)) {
                Stepper(value : $model.fiscalModel.pensionTaxes.model.CSGdeductible,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CSG déductible")
                        Spacer()
                        Text("\(model.fiscalModel.pensionTaxes.model.CSGdeductible.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.pensionTaxes.model.CSGdeductible) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.fiscalModel.pensionTaxes.model.CRDS,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CRDS")
                        Spacer()
                        Text("\(model.fiscalModel.pensionTaxes.model.CRDS.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.pensionTaxes.model.CRDS) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.fiscalModel.pensionTaxes.model.CSG,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CSG")
                        Spacer()
                        Text("\(model.fiscalModel.pensionTaxes.model.CSG.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.pensionTaxes.model.CSG) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.fiscalModel.pensionTaxes.model.additionalContrib,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Contribution additionnelle")
                        Spacer()
                        Text("\(model.fiscalModel.pensionTaxes.model.additionalContrib.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.pensionTaxes.model.additionalContrib) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.fiscalModel.pensionTaxes.model.healthInsurance,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cotisation Assurance Santé")
                        Spacer()
                        Text("\(model.fiscalModel.pensionTaxes.model.healthInsurance.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.pensionTaxes.model.healthInsurance) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
        }
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

struct ModelFiscalPensionView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelFiscalPensionView()
            .preferredColorScheme(.dark)
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
