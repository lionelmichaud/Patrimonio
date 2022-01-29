//
//  ModelFiscalChomageChargeView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalChomageChargeView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Stepper(value : $viewModel.fiscalModel.allocationChomageTaxes.model.assiette,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("Assiette")
                    Spacer()
                    Text("\(viewModel.fiscalModel.allocationChomageTaxes.model.assiette.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.allocationChomageTaxes.model.assiette) { _ in viewModel.isModified = true }

            AmountEditView(label  : "Seuil de Taxation CSG/CRDS",
                           comment: "journalier",
                           amount : $viewModel.fiscalModel.allocationChomageTaxes.model.seuilCsgCrds)
                .onChange(of: viewModel.fiscalModel.allocationChomageTaxes.model.seuilCsgCrds) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.fiscalModel.allocationChomageTaxes.model.CRDS,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("CRDS")
                    Spacer()
                    Text("\(viewModel.fiscalModel.allocationChomageTaxes.model.CRDS.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.allocationChomageTaxes.model.CRDS) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.fiscalModel.allocationChomageTaxes.model.CSG,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("CSG")
                    Spacer()
                    Text("\(viewModel.fiscalModel.allocationChomageTaxes.model.CSG.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.allocationChomageTaxes.model.CSG) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.fiscalModel.allocationChomageTaxes.model.retraiteCompl,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("Cotisation de Retraite Complémentaire")
                    Spacer()
                    Text("\(viewModel.fiscalModel.allocationChomageTaxes.model.retraiteCompl.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.allocationChomageTaxes.model.retraiteCompl) { _ in viewModel.isModified = true }

            AmountEditView(label  : "Seuil de Taxation Retraite Complémentaire",
                           comment: "journalier",
                           amount : $viewModel.fiscalModel.allocationChomageTaxes.model.seuilRetCompl)
                .onChange(of: viewModel.fiscalModel.allocationChomageTaxes.model.seuilRetCompl) { _ in viewModel.isModified = true }
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
        .navigationTitle("Allocation Chômage")
    }
}

struct ModelFiscalChomageChargeView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalChomageChargeView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
