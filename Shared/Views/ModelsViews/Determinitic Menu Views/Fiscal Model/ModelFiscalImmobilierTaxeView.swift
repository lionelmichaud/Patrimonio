//
//  ModelFiscalImmobilierTaxeView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalImmobilierTaxeView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            Section {
                VersionEditableView(version: $viewModel.fiscalModel.estateCapitalGainTaxes.model.version)
                    .onChange(of: viewModel.fiscalModel.estateCapitalGainTaxes.model.version) { _ in viewModel.isModified = true }
            }
            
            NavigationLink(destination: RealEstateExonerationGridView(label: "Barême des taxes sur Plus-Values Immobilières",
                                                                      grid: $viewModel.fiscalModel.estateCapitalGainTaxes.model.exoGrid)
                            .environmentObject(viewModel)) {
                Text("Barême des taxes sur Plus-Values Immobilières")
            }.isDetailLink(true)

            Stepper(value : $viewModel.fiscalModel.estateCapitalGainTaxes.model.CRDS,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("CRDS")
                    Spacer()
                    Text("\(viewModel.fiscalModel.estateCapitalGainTaxes.model.CRDS.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.estateCapitalGainTaxes.model.CRDS) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.fiscalModel.estateCapitalGainTaxes.model.CSG,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("CSG")
                    Spacer()
                    Text("\(viewModel.fiscalModel.estateCapitalGainTaxes.model.CSG.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.estateCapitalGainTaxes.model.CSG) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.fiscalModel.estateCapitalGainTaxes.model.prelevSocial,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("Prélèvements Sociaux")
                    Spacer()
                    Text("\(viewModel.fiscalModel.estateCapitalGainTaxes.model.prelevSocial.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.estateCapitalGainTaxes.model.prelevSocial) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.fiscalModel.estateCapitalGainTaxes.model.discountTravaux,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Abattement forfaitaire pour travaux")
                    Spacer()
                    Text("\(viewModel.fiscalModel.estateCapitalGainTaxes.model.discountTravaux.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.estateCapitalGainTaxes.model.discountTravaux) { _ in viewModel.isModified = true }

            IntegerEditView(label   : "Abattement possible après",
                            comment : "ans",
                            integer : $viewModel.fiscalModel.estateCapitalGainTaxes.model.discountAfter)
                .onChange(of: viewModel.fiscalModel.estateCapitalGainTaxes.model.discountAfter) { _ in viewModel.isModified = true }
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
        .navigationTitle("Plus-Value Immobilière")
    }
}

struct ModelFiscalImmobilierTaxeView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalImmobilierTaxeView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
