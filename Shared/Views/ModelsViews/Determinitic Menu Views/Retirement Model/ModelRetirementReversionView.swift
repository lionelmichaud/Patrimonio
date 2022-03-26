//
//  ModelRetirementReversionView.swift
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

// MARK: - Deterministic Retirement Pension de Réversion View

struct ModelRetirementReversionView : View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    @State private var isExpandedCurrent        : Bool = false
    @State private var isExpandedCurrentGeneral : Bool = false
    @State private var isExpandedCurrentAgirc   : Bool = false
    @State private var isExpandedFutur          : Bool = false
    
    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $model.retirementModel.reversion.model.version)
            }
            
            Toggle("Utiliser la réforme des retraites",
                   isOn: $model.retirementModel.reversion.newModelSelected)

            Section(header: Text("Système Réformé Futur").font(.headline)) {
                Stepper(value : $model.retirementModel.reversion.newTauxReversion,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Taux de réversion")
                        Spacer()
                        Text("\(model.retirementModel.reversion.newTauxReversion.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Système Actuel").font(.headline)) {
                DisclosureGroup("Régime Général",
                                isExpanded: $isExpandedCurrentGeneral) {
                    AmountEditView(label: "Minimum", amount: $model.retirementModel.reversion.oldModel.general.minimum)

                    Stepper(value : $model.retirementModel.reversion.oldModel.general.majoration3enfants,
                            in    : 0 ... 100.0,
                            step  : 1.0) {
                        HStack {
                            Text("Majoration pour 3 enfants nés")
                            Spacer()
                            Text("\(model.retirementModel.reversion.oldModel.general.majoration3enfants.percentString(digit: 0))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DisclosureGroup("Régime Complémentaire",
                                isExpanded: $isExpandedCurrentAgirc) {
                    Stepper(value : $model.retirementModel.reversion.oldModel.agircArcco.ageMinimum,
                            in    : 50 ... 100) {
                        HStack {
                            Text("Age minimum pour perçevoir la pension de réversion")
                            Spacer()
                            Text("\(model.retirementModel.reversion.oldModel.agircArcco.ageMinimum) ans")
                                .foregroundColor(.secondary)
                        }
                    }

                    Stepper(value : $model.retirementModel.reversion.oldModel.agircArcco.fractionConjoint,
                            in    : 0 ... 100.0,
                            step  : 1.0) {
                        HStack {
                            Text("Fraction des points du conjoint décédé")
                            Spacer()
                            Text("\(model.retirementModel.reversion.oldModel.agircArcco.fractionConjoint.percentString(digit: 0))")
                                .foregroundColor(.secondary)
                        }
                    }

                }
            }
        }
        .onChange(of: model.retirementModel.reversion.model) { _ in
            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
            model.manageInternalDependencies()
        }
        .navigationTitle("Régime Général")
        .alert(item: $alertItem, content: newAlert)
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

struct ModelRetirementReversionView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelRetirementReversionView()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
