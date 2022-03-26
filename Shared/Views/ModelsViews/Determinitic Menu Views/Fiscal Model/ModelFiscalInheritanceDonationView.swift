//
//  ModelFiscalInheritanceDonationView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel
import SimulationAndVisitors
import HelpersView

struct ModelFiscalInheritanceDonationView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            VersionEditableViewInForm(version: $model.fiscalModel.inheritanceDonation.model.version)

            Section(header: Text("Entre Conjoint").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême Donation Conjoint",
                                                         grid: $model.fiscalModel.inheritanceDonation.model.gridDonationConjoint)
                                .environmentObject(model)) {
                    Text("Barême pour Donation entre Conjoint")
                }.isDetailLink(true)
                
                AmountEditView(label  : "Abattement sur Donation au Conjoint",
                               amount : $model.fiscalModel.inheritanceDonation.model.abatConjoint)
            }
            
            Section(header: Text("En Ligne Directe").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême Donation Ligne Directe",
                                                         grid: $model.fiscalModel.inheritanceDonation.model.gridLigneDirecte)
                                .environmentObject(model)) {
                    Text("Barême pour Donation en Ligne Directe")
                }.isDetailLink(true)
                
                AmountEditView(label  : "Abattement sur Donation/Succession en ligne directe",
                               amount : $model.fiscalModel.inheritanceDonation.model.abatLigneDirecte)
            }
            
            AmountEditView(label  : "Abattement sur Succession pour frais Funéraires",
                           amount : $model.fiscalModel.inheritanceDonation.model.fraisFunéraires)

            Stepper(value : $model.fiscalModel.inheritanceDonation.model.decoteResidence,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Décote sur la Résidence Principale")
                    Spacer()
                    Text("\(model.fiscalModel.inheritanceDonation.model.decoteResidence.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onChange(of: model.fiscalModel.inheritanceDonation.model) { _ in
            DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
            model.manageInternalDependencies()
        }
        .navigationTitle("Succession et Donation")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    model     : model,
                    notifyTemplatFolderMissing: {
                        DispatchQueue.main.async {
                            alertItem =
                            AlertItem(title         : Text("Répertoire 'Patron' absent"),
                                      dismissButton : .default(Text("OK")))
                        }
                    },
                    notifyFailure: {
                        DispatchQueue.main.async {
                            alertItem =
                            AlertItem(title         : Text("Echec de l'enregistrement"),
                                      dismissButton : .default(Text("OK")))
                        }
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

struct ModelFiscalInheritanceDonationView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelFiscalInheritanceDonationView()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
