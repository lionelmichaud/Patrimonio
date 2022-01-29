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

struct ModelFiscalImpotSocieteView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            Stepper(value : $viewModel.fiscalModel.companyProfitTaxes.model.rate,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Taux d'impôt sur les bénéfices")
                    Spacer()
                    Text("\(viewModel.fiscalModel.companyProfitTaxes.model.rate.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.companyProfitTaxes.model.rate) { _ in viewModel.isModified = true }
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
        .navigationTitle("Bénéfice des Sociétés (IS)")
    }
}

struct ModelFiscalImpotSocieteView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalImpotSocieteView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
