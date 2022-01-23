//
//  ModelFiscalIrppView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalIrppView: View {
    @ObservedObject var viewModel             : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            DisclosureGroup() {
                Stepper(value : $viewModel.fiscalModel.incomeTaxes.model.salaryRebate,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(viewModel.fiscalModel.incomeTaxes.model.salaryRebate.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.incomeTaxes.model.salaryRebate) { _ in viewModel.isModified = true }
                
                AmountEditView(label  : "Abattement minimum",
                               amount : $viewModel.fiscalModel.incomeTaxes.model.minSalaryRebate)
                    .onChange(of: viewModel.fiscalModel.incomeTaxes.model.minSalaryRebate) { _ in viewModel.isModified = true }
                
                AmountEditView(label  : "Abattement maximum",
                               amount : $viewModel.fiscalModel.incomeTaxes.model.maxSalaryRebate)
                    .onChange(of: viewModel.fiscalModel.incomeTaxes.model.maxSalaryRebate) { _ in viewModel.isModified = true }
                
                AmountEditView(label  : "Plafond de Réduction d'Impôt par Enfant",
                               amount : $viewModel.fiscalModel.incomeTaxes.model.childRebate)
                    .onChange(of: viewModel.fiscalModel.incomeTaxes.model.childRebate) { _ in viewModel.isModified = true }
            }
            label: {
                Text("Salaire").textCase(.uppercase).font(.headline)
            }
            
            DisclosureGroup() {
                Stepper(value : $viewModel.fiscalModel.incomeTaxes.model.turnOverRebate,
                        in    : 0 ... 100.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(viewModel.fiscalModel.incomeTaxes.model.turnOverRebate.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.incomeTaxes.model.turnOverRebate) { _ in viewModel.isModified = true }
                
                AmountEditView(label  : "Abattement minimum",
                               amount : $viewModel.fiscalModel.incomeTaxes.model.minTurnOverRebate)
                    .onChange(of: viewModel.fiscalModel.incomeTaxes.model.minTurnOverRebate) { _ in viewModel.isModified = true }
            }
            label: {
                Text("BNC").textCase(.uppercase).font(.headline)
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
        .navigationTitle("Imposition sur le Revenu")
    }
}

struct ModelFiscalIrppView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelFiscalIrppView(viewModel: DeterministicViewModel(using: modelTest))
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
