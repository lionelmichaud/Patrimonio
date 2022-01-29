//
//  ModelFiscalIrppView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import FamilyModel

struct ModelFiscalIrppView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    @State private var showingSheet = false
    
    var body: some View {
        Form {
            DisclosureGroup() {
                NavigationLink(destination: RateGridView(label: "Barême IRPP",
                                                         grid: $viewModel.fiscalModel.incomeTaxes.model.grid)
                                .environmentObject(viewModel)) {
                    Text("Barême")
                }.isDetailLink(true)
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
        /// barre d'outils
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
                        viewModel  : viewModel,
                        model      : model,
                        family     : family,
                        simulation : simulation)
                })
                .disabled(!viewModel.isModified)
            }
        }
        .navigationTitle("Revenus du Travail")
    }
}

struct ModelFiscalIrppView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalIrppView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
