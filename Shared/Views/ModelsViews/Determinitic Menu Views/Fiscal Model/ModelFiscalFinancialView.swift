//
//  ModelFiscalFinancialView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalFinancialView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            Section(footer: Text("Appliquable à tous les revenus financiers")) {
                Stepper(value : $viewModel.fiscalModel.financialRevenuTaxes.model.CRDS,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CRDS")
                        Spacer()
                        Text("\(viewModel.fiscalModel.financialRevenuTaxes.model.CRDS.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.financialRevenuTaxes.model.CRDS) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.financialRevenuTaxes.model.CSG,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CSG")
                        Spacer()
                        Text("\(viewModel.fiscalModel.financialRevenuTaxes.model.CSG.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.financialRevenuTaxes.model.CSG) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.financialRevenuTaxes.model.prelevSocial,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Prélèvement Sociaux")
                        Spacer()
                        Text("\(viewModel.fiscalModel.financialRevenuTaxes.model.prelevSocial.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.financialRevenuTaxes.model.prelevSocial) { _ in viewModel.isModified = true }
            }
        }
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    viewModel : viewModel,
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
            applyChangesToDossier: {
                alertItem = applyChangesToOpenDossierAlert(
                    viewModel  : viewModel,
                    model      : model,
                    family     : family,
                    simulation : simulation)
            },
            isModified: viewModel.isModified)
        .navigationTitle("Revenus Financiers")
    }
}

struct ModelFiscalFinancialView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalFinancialView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
