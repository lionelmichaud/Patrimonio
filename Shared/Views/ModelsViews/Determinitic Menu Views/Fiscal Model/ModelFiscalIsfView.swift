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
import HelpersView

struct ModelFiscalIsfView: View {
    @EnvironmentObject private var dataStore  : Store
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
            Section {
                VersionEditableViewInForm(version: $model.fiscalModel.isf.model.version)
                    .onChange(of: model.fiscalModel.isf.model.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            NavigationLink(destination: RateGridView(label: "Barême ISF/IFI",
                                                     grid: $model.fiscalModel.isf.model.grid)
                            .environmentObject(model)) {
                Text("Barême")
            }.isDetailLink(true)
            
            Section(header: Text("Calcul").font(.headline),
                    footer: Text(footnote)) {
                AmountEditView(label  : "Seuil d'imposition",
                               amount : $model.fiscalModel.isf.model.seuil)
                    .onChange(of: model.fiscalModel.isf.model.seuil) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
                AmountEditView(label  : "Limite supérieure de la tranche de transition",
                               amount : $model.fiscalModel.isf.model.seuil2)
                    .onChange(of: model.fiscalModel.isf.model.seuil2) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
                AmountEditView(label  : "Décote maximale",
                               amount : $model.fiscalModel.isf.model.decote€)
                    .onChange(of: model.fiscalModel.isf.model.decote€) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
                Stepper(value : $model.fiscalModel.isf.model.decoteCoef,
                        in    : 0 ... 100.0,
                        step  : 0.25) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(model.fiscalModel.isf.model.decoteCoef.percentString(digit: 2))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.isf.model.decoteCoef) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
            
            Section(header: Text("Décotes Spécifiques").font(.headline)) {
                Stepper(value : $model.fiscalModel.isf.model.decoteResidence,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur de la résidence principale")
                        Spacer()
                        Text("\(model.fiscalModel.isf.model.decoteResidence.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.isf.model.decoteResidence) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
                
                Stepper(value : $model.fiscalModel.isf.model.decoteLocation,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur d'un bien immobilier en location")
                        Spacer()
                        Text("\(model.fiscalModel.isf.model.decoteLocation.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.isf.model.decoteLocation) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
                
                Stepper(value : $model.fiscalModel.isf.model.decoteIndivision,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur d'un bien immobilier en indivision")
                        Spacer()
                        Text("\(model.fiscalModel.isf.model.decoteIndivision.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.fiscalModel.isf.model.decoteIndivision) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
        }
        .navigationTitle("Imposition sur le Capital")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
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
            cancelChanges: {
                alertItem = cancelChanges(
                    to         : model,
                    family     : family,
                    simulation : simulation,
                    dataStore  : dataStore)
            },
            isModified: model.isModified)
    }
}

struct ModelFiscalIsfView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelFiscalIsfView()
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .preferredColorScheme(.dark)
    }
}
