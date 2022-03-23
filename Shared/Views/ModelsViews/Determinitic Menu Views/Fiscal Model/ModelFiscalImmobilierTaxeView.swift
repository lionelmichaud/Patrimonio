//
//  ModelFiscalImmobilierTaxeView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel
import SimulationAndVisitors
import HelpersView

struct ModelFiscalImmobilierTaxeView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $model.fiscalModel.estateCapitalGainTaxes.model.version)
                    .onChange(of: model.fiscalModel.estateCapitalGainTaxes.model.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            NavigationLink(destination: RealEstateExonerationGridView(label: "Barême des taxes sur Plus-Values Immobilières",
                                                                      grid: $model.fiscalModel.estateCapitalGainTaxes.model.exoGrid)
                            .environmentObject(model)) {
                Text("Barême des taxes sur Plus-Values Immobilières")
            }.isDetailLink(true)

            Stepper(value : $model.fiscalModel.estateCapitalGainTaxes.model.CRDS,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("CRDS")
                    Spacer()
                    Text("\(model.fiscalModel.estateCapitalGainTaxes.model.CRDS.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.estateCapitalGainTaxes.model.CRDS) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            Stepper(value : $model.fiscalModel.estateCapitalGainTaxes.model.CSG,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("CSG")
                    Spacer()
                    Text("\(model.fiscalModel.estateCapitalGainTaxes.model.CSG.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.estateCapitalGainTaxes.model.CSG) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            Stepper(value : $model.fiscalModel.estateCapitalGainTaxes.model.prelevSocial,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("Prélèvements Sociaux")
                    Spacer()
                    Text("\(model.fiscalModel.estateCapitalGainTaxes.model.prelevSocial.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.estateCapitalGainTaxes.model.prelevSocial) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            Stepper(value : $model.fiscalModel.estateCapitalGainTaxes.model.discountTravaux,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Abattement forfaitaire pour travaux")
                    Spacer()
                    Text("\(model.fiscalModel.estateCapitalGainTaxes.model.discountTravaux.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.estateCapitalGainTaxes.model.discountTravaux) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            IntegerEditView(label   : "Abattement possible après",
                            comment : "ans",
                            integer : $model.fiscalModel.estateCapitalGainTaxes.model.discountAfter)
                .onChange(of: model.fiscalModel.estateCapitalGainTaxes.model.discountAfter) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
        }
        .navigationTitle("Plus-Value Immobilière")
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

struct ModelFiscalImmobilierTaxeView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelFiscalImmobilierTaxeView()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
