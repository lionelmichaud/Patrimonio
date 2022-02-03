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

// MARK: - Deterministic Retirement Pension de Réversion View

struct ModelRetirementReversionView : View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var isExpandedCurrent        : Bool = false
    @State private var isExpandedCurrentGeneral : Bool = false
    @State private var isExpandedCurrentAgirc   : Bool = false
    @State private var isExpandedFutur          : Bool = false
    @State private var alertItem                : AlertItem?

    var body: some View {
        Form {
            VersionView(version: $viewModel.retirementModel.reversion.model.version)
                .onChange(of: viewModel.retirementModel.reversion.model.version) { _ in viewModel.isModified = true }

            Toggle("Utiliser la réforme des retraites",
                   isOn: $viewModel.retirementModel.reversion.newModelSelected)
                .onChange(of: viewModel.retirementModel.reversion.newModelSelected) { _ in viewModel.isModified = true }
            
            Section(header: Text("Système Réformé Futur").font(.headline)) {
                Stepper(value : $viewModel.retirementModel.reversion.newTauxReversion,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Taux de réversion")
                        Spacer()
                        Text("\(viewModel.retirementModel.reversion.newTauxReversion.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.retirementModel.reversion.newTauxReversion) { _ in viewModel.isModified = true }
            }
            
            Section(header: Text("Système Actuel").font(.headline)) {
                DisclosureGroup("Régime Général",
                                isExpanded: $isExpandedCurrentGeneral) {
                    AmountEditView(label: "Minimum", amount: $viewModel.retirementModel.reversion.oldModel.general.minimum)
                        .onChange(of: viewModel.retirementModel.reversion.oldModel.general.minimum) { _ in viewModel.isModified = true }
                    Stepper(value : $viewModel.retirementModel.reversion.oldModel.general.majoration3enfants,
                            in    : 0 ... 100.0,
                            step  : 1.0) {
                        HStack {
                            Text("Majoration pour 3 enfants nés")
                            Spacer()
                            Text("\(viewModel.retirementModel.reversion.oldModel.general.majoration3enfants.percentString(digit: 0)) %").foregroundColor(.secondary)
                        }
                    }.onChange(of: viewModel.retirementModel.reversion.oldModel.general.majoration3enfants) { _ in viewModel.isModified = true }
                }
                DisclosureGroup("Régime Complémentaire",
                                isExpanded: $isExpandedCurrentAgirc) {
                    Stepper(value : $viewModel.retirementModel.reversion.oldModel.agircArcco.ageMinimum,
                            in    : 50 ... 100) {
                        HStack {
                            Text("Age minimum pour perçevoir la pension de réversion")
                            Spacer()
                            Text("\(viewModel.retirementModel.reversion.oldModel.agircArcco.ageMinimum) ans").foregroundColor(.secondary)
                        }
                    }.onChange(of: viewModel.retirementModel.reversion.oldModel.agircArcco.ageMinimum) { _ in viewModel.isModified = true }
                    Stepper(value : $viewModel.retirementModel.reversion.oldModel.agircArcco.fractionConjoint,
                            in    : 0 ... 100.0,
                            step  : 1.0) {
                        HStack {
                            Text("Fraction des points du conjoint décédé")
                            Spacer()
                            Text("\(viewModel.retirementModel.reversion.oldModel.agircArcco.fractionConjoint.percentString(digit: 0)) %").foregroundColor(.secondary)
                        }
                    }.onChange(of: viewModel.retirementModel.reversion.oldModel.agircArcco.fractionConjoint) { _ in viewModel.isModified = true }
                }
            }
        }
        .alert(item: $alertItem, content: newAlert)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                DiskButton(text   : "Modifier le Patron",
                           action : {
                            alertItem = applyChangesToTemplateAlert(
                                viewModel: viewModel,
                                model: model,
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
                           })
            }
            ToolbarItem(placement: .automatic) {
                FolderButton(action : {
                    alertItem = applyChangesToOpenDossierAlert(
                        viewModel: viewModel,
                        model: model,
                        family: family,
                        simulation: simulation)
                })
                .disabled(!viewModel.isModified)
            }
        }
        .navigationTitle("Régime Général")
    }
}

struct ModelRetirementReversionView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelRetirementReversionView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
