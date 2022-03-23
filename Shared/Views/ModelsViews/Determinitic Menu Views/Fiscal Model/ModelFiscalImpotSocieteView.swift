//
//  ModelFiscalImpotSocieteView.swift
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

struct ModelFiscalImpotSocieteView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $model.fiscalModel.companyProfitTaxes.model.version)
                .onChange(of: model.fiscalModel.companyProfitTaxes.model.version) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

            Stepper(value : $model.fiscalModel.companyProfitTaxes.model.rate,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Taux d'impôt sur les bénéfices")
                    Spacer()
                    Text("\(model.fiscalModel.companyProfitTaxes.model.rate.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.companyProfitTaxes.model.rate) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }
        }
        .navigationTitle("Bénéfice des Sociétés (IS)")
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

struct ModelFiscalImpotSocieteView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelFiscalImpotSocieteView()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
