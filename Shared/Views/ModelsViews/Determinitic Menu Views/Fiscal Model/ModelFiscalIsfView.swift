//
//  ModelFiscalIsfView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel

struct ModelFiscalIsfView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    let footnote: String =
        """
        Un système d'abattement progressif a été mis en place pour les patrimoines nets taxables compris entre 1,3 million et 1,4 million d’euros.
        Le montant de la décote est calculé selon la formule 17 500 – (1,25 % x montant du patrimoine net taxable).
        """
    
    var body: some View {
        Form {
            VersionView(version: $viewModel.fiscalModel.isf.model.version)
                .onChange(of: viewModel.fiscalModel.isf.model.version) { _ in viewModel.isModified = true }

            NavigationLink(destination: RateGridView(label: "Barême ISF/IFI",
                                                     grid: $viewModel.fiscalModel.isf.model.grid)
                            .environmentObject(viewModel)) {
                Text("Barême")
            }.isDetailLink(true)

            Section(header: Text("Calcul").font(.headline),
                footer: Text(footnote)) {
                AmountEditView(label  : "Seuil d'imposition",
                               amount : $viewModel.fiscalModel.isf.model.seuil)
                    .onChange(of: viewModel.fiscalModel.isf.model.seuil) { _ in viewModel.isModified = true }
                AmountEditView(label  : "Limite supérieure de la tranche de transition",
                               amount : $viewModel.fiscalModel.isf.model.seuil2)
                    .onChange(of: viewModel.fiscalModel.isf.model.seuil2) { _ in viewModel.isModified = true }
                
                AmountEditView(label  : "Décote maximale",
                               amount : $viewModel.fiscalModel.isf.model.decote€)
                    .onChange(of: viewModel.fiscalModel.isf.model.decote€) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.isf.model.decoteCoef,
                        in    : 0 ... 100.0,
                        step  : 0.25) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(viewModel.fiscalModel.isf.model.decoteCoef.percentString(digit: 2)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.isf.model.decoteCoef) { _ in viewModel.isModified = true }
            }
            
            Section(header: Text("Décotes Spécifiques").font(.headline)) {
                Stepper(value : $viewModel.fiscalModel.isf.model.decoteResidence,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur de la résidence principale")
                        Spacer()
                        Text("\(viewModel.fiscalModel.isf.model.decoteResidence.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.isf.model.decoteResidence) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.isf.model.decoteLocation,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur d'un bien immobilier en location")
                        Spacer()
                        Text("\(viewModel.fiscalModel.isf.model.decoteLocation.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.isf.model.decoteLocation) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.fiscalModel.isf.model.decoteIndivision,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur d'un bien immobilier en indivision")
                        Spacer()
                        Text("\(viewModel.fiscalModel.isf.model.decoteIndivision.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.fiscalModel.isf.model.decoteIndivision) { _ in viewModel.isModified = true }
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
        .navigationTitle("Imposition sur le Capital")
    }
}

struct ModelFiscalIsfView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelFiscalIsfView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
