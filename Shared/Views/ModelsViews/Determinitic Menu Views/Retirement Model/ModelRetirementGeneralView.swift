//
//  ModelRetirementGeneralView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

// MARK: - Deterministic Retirement Régime General View

struct ModelRetirementGeneralView: View {
    @ObservedObject var viewModel             : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            Stepper(value : $viewModel.ageMinimumLegal,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum légal de liquidation")
                    Spacer()
                    Text("\(viewModel.ageMinimumLegal) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.ageMinimumLegal) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.maxReversionRate,
                    in    : 50 ... 100,
                    step  : 1.0) {
                HStack {
                    Text("Taux maximum")
                    Spacer()
                    Text("\(viewModel.maxReversionRate.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.maxReversionRate) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.decoteParTrimestre,
                    in    : 0 ... 1.5,
                    step  : 0.025) {
                HStack {
                    Text("Décote par trimestre manquant")
                    Spacer()
                    Text("\(viewModel.decoteParTrimestre.percentString(digit: 3)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.decoteParTrimestre) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.surcoteParTrimestre,
                    in    : 0 ... 2.5,
                    step  : 0.25) {
                HStack {
                    Text("Surcote par trimestre supplémentaire")
                    Spacer()
                    Text("\(viewModel.surcoteParTrimestre.percentString(digit: 2)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.surcoteParTrimestre) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.maxNbTrimestreDecote,
                    in    : 10 ... 30,
                    step  : 1) {
                HStack {
                    Text("Nombre de trimestres maximum de décote")
                    Spacer()
                    Text("\(viewModel.maxNbTrimestreDecote) trimestres").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.maxNbTrimestreDecote) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.majorationTauxEnfant,
                    in    : 0 ... 20.0,
                    step  : 1.0) {
                HStack {
                    Text("Surcote pour trois enfants nés")
                    Spacer()
                    Text("\(viewModel.majorationTauxEnfant.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.majorationTauxEnfant) { _ in viewModel.isModified = true }
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
                                        AlertItem(title         : Text("Répertoire 'Modèle' absent"),
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

struct ModelRetirementGeneralView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelRetirementGeneralView(viewModel: DeterministicViewModel(using: modelTest))
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
