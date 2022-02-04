//
//  ModelFiscalPensionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalPensionView: View {
    @EnvironmentObject private var viewModel: DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            VersionEditableView(version: $viewModel.fiscalModel.pensionTaxes.model.version)
                .onChange(of: viewModel.fiscalModel.pensionTaxes.model.version) { _ in viewModel.isModified = true }

            Section(header: Text("Abattement").font(.headline)) {
                Stepper(value : $viewModel.fiscalModel.pensionTaxes.model.rebate,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(viewModel.fiscalModel.pensionTaxes.model.rebate.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.pensionTaxes.model.rebate) { _ in viewModel.isModified = true }
                
                AmountEditView(label  : "Abattement minimum",
                               amount : $viewModel.fiscalModel.pensionTaxes.model.minRebate)
                    .onChange(of: viewModel.fiscalModel.pensionTaxes.model.minRebate) { _ in viewModel.isModified = true }
                
                AmountEditView(label  : "Abattement maximum",
                               amount : $viewModel.fiscalModel.pensionTaxes.model.maxRebate)
                    .onChange(of: viewModel.fiscalModel.pensionTaxes.model.maxRebate) { _ in viewModel.isModified = true }
            }
            
            Section(header: Text("Taux de Cotisation").font(.headline)) {
                Stepper(value : $viewModel.fiscalModel.pensionTaxes.model.CSGdeductible,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CSG déductible")
                        Spacer()
                        Text("\(viewModel.fiscalModel.pensionTaxes.model.CSGdeductible.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.pensionTaxes.model.CSGdeductible) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.pensionTaxes.model.CRDS,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CRDS")
                        Spacer()
                        Text("\(viewModel.fiscalModel.pensionTaxes.model.CRDS.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.pensionTaxes.model.CRDS) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.pensionTaxes.model.CSG,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CSG")
                        Spacer()
                        Text("\(viewModel.fiscalModel.pensionTaxes.model.CSG.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.pensionTaxes.model.CSG) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.pensionTaxes.model.additionalContrib,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Contribution additionnelle")
                        Spacer()
                        Text("\(viewModel.fiscalModel.pensionTaxes.model.additionalContrib.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.pensionTaxes.model.additionalContrib) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.pensionTaxes.model.healthInsurance,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cotisation Assurance Santé")
                        Spacer()
                        Text("\(viewModel.fiscalModel.pensionTaxes.model.healthInsurance.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.pensionTaxes.model.healthInsurance) { _ in viewModel.isModified = true }
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
        .navigationTitle("Pensions de Retraite")
    }
}

struct ModelFiscalPensionView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalPensionView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
