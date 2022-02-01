//
//  ModelFiscalImmobilierImpot.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalImmobilierImpotView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            VersionView(version: $viewModel.fiscalModel.estateCapitalGainIrpp.model.version)
                .onChange(of: viewModel.fiscalModel.estateCapitalGainIrpp.model.version) { _ in viewModel.isModified = true }

            NavigationLink(destination: RealEstateExonerationGridView(label: "Barême de l'Impôts sur Plus-Values Immobilières",
                                                                      grid: $viewModel.fiscalModel.estateCapitalGainIrpp.model.exoGrid)
                            .environmentObject(viewModel)) {
                Text("Barême de l'Impôts sur Plus-Values Immobilières")
            }.isDetailLink(true)

            Stepper(value : $viewModel.fiscalModel.estateCapitalGainIrpp.model.irpp,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Taux d'impôt sur les plus-values")
                    Spacer()
                    Text("\(viewModel.fiscalModel.estateCapitalGainIrpp.model.irpp.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.fiscalModel.estateCapitalGainIrpp.model.irpp) { _ in viewModel.isModified = true }
            
            Section(header: Text("Abattement").font(.headline)) {
                Stepper(value : $viewModel.fiscalModel.estateCapitalGainIrpp.model.discountTravaux,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Abattement forfaitaire pour travaux")
                        Spacer()
                        Text("\(viewModel.fiscalModel.estateCapitalGainIrpp.model.discountTravaux.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.estateCapitalGainIrpp.model.discountTravaux) { _ in viewModel.isModified = true }
                
                IntegerEditView(label   : "Abattement possible après",
                                comment : "ans",
                                integer : $viewModel.fiscalModel.estateCapitalGainIrpp.model.discountAfter)
                    .onChange(of: viewModel.fiscalModel.estateCapitalGainIrpp.model.discountAfter) { _ in viewModel.isModified = true }
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
        .navigationTitle("Plus-Value Immobilière")
    }
}

struct ModelFiscalImmobilierImpot_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalImmobilierImpotView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
