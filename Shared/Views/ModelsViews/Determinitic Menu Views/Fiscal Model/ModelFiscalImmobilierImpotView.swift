//
//  ModelFiscalImmobilierImpot.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel
import HelpersView

struct ModelFiscalImmobilierImpotView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $model.fiscalModel.estateCapitalGainIrpp.model.version)
                    .onChange(of: model.fiscalModel.estateCapitalGainIrpp.model.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            NavigationLink(destination: RealEstateExonerationGridView(label: "Barême de l'Impôts sur Plus-Values Immobilières",
                                                                      grid: $model.fiscalModel.estateCapitalGainIrpp.model.exoGrid)
                            .environmentObject(model)) {
                Text("Barême de l'Impôts sur Plus-Values Immobilières")
            }.isDetailLink(true)

            Stepper(value : $model.fiscalModel.estateCapitalGainIrpp.model.irpp,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Taux d'impôt sur les plus-values")
                    Spacer()
                    Text("\(model.fiscalModel.estateCapitalGainIrpp.model.irpp.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }
            .onChange(of: model.fiscalModel.estateCapitalGainIrpp.model.irpp) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }
            
            Section(header: Text("Abattement").font(.headline)) {
                Stepper(value : $model.fiscalModel.estateCapitalGainIrpp.model.discountTravaux,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Abattement forfaitaire pour travaux")
                        Spacer()
                        Text("\(model.fiscalModel.estateCapitalGainIrpp.model.discountTravaux.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.estateCapitalGainIrpp.model.discountTravaux) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
                
                IntegerEditView(label   : "Abattement possible après",
                                comment : "ans",
                                integer : $model.fiscalModel.estateCapitalGainIrpp.model.discountAfter)
                    .onChange(of: model.fiscalModel.estateCapitalGainIrpp.model.discountAfter) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
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

struct ModelFiscalImmobilierImpot_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelFiscalImmobilierImpotView()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
