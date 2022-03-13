//
//  ModelRetirementAgircView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import Persistence
import FamilyModel
import HelpersView

// MARK: - Deterministic Retirement Régime Complémentaire View

struct ModelRetirementAgircView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    @State private var isExpandedMajoration   : Bool = false
    
    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $model.retirementModel.regimeAgirc.model.version)
                    .onChange(of: model.retirementModel.regimeAgirc.model.version) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }
            }
            
            Stepper(value : $model.retirementModel.regimeAgirc.ageMinimum,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum de liquidation")
                    Spacer()
                    Text("\(model.retirementModel.regimeAgirc.ageMinimum) ans").foregroundColor(.secondary)
                }
            }
            .onChange(of: model.retirementModel.regimeAgirc.ageMinimum) { _ in
                DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                model.manageInternalDependencies()
            }

            AmountEditView(label  : "Valeur du point",
                           amount : $model.retirementModel.regimeAgirc.valeurDuPoint)
                .onChange(of: model.retirementModel.regimeAgirc.valeurDuPoint) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

            NavigationLink(destination: AgircAvantAgeLegalGridView(label: "Réduction pour trimestres manquant avant l'âge légale",
                                                                   grid: $model.retirementModel.regimeAgirc.gridAvantAgeLegal)
                            .environmentObject(model)) {
                Text("Réduction pour trimestres manquant avant l'âge légale")
            }.isDetailLink(true)

            NavigationLink(destination: AgircApresAgeLegalGridView(label: "Réduction pour trimestres manquant après l'âge légale",
                                                                   grid: $model.retirementModel.regimeAgirc.gridApresAgelegal)
                            .environmentObject(model)) {
                Text("Réduction pour trimestres manquant après l'âge légale")
            }.isDetailLink(true)

            Section(header: Text("Majoration pour Enfants").font(.headline)) {
                Stepper(value : $model.retirementModel.regimeAgirc.majorationPourEnfant.majorPourEnfantsNes,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants nés")
                        Spacer()
                        Text("\(model.retirementModel.regimeAgirc.majorationPourEnfant.majorPourEnfantsNes.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.retirementModel.regimeAgirc.majorationPourEnfant.majorPourEnfantsNes) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                Stepper(value : $model.retirementModel.regimeAgirc.majorationPourEnfant.nbEnafntNesMin,
                        in    : 1 ... 4,
                        step  : 1) {
                    HStack {
                        Text("Nombre d'enfants nés pour obtenir la majoration")
                        Spacer()
                        Text("\(model.retirementModel.regimeAgirc.majorationPourEnfant.nbEnafntNesMin) enfants")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.retirementModel.regimeAgirc.majorationPourEnfant.nbEnafntNesMin) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }

                AmountEditView(label   : "Plafond pour enfants nés",
                               comment : "annuel",
                               amount  : $model.retirementModel.regimeAgirc.majorationPourEnfant.plafondMajoEnfantNe)
                    .onChange(of: model.retirementModel.regimeAgirc.majorationPourEnfant.plafondMajoEnfantNe) { _ in
                        DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                        model.manageInternalDependencies()
                    }

                Stepper(value : $model.retirementModel.regimeAgirc.majorationPourEnfant.majorParEnfantACharge,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants à charge")
                        Spacer()
                        Text("\(model.retirementModel.regimeAgirc.majorationPourEnfant.majorParEnfantACharge.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: model.retirementModel.regimeAgirc.majorationPourEnfant.majorParEnfantACharge) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
        }
        .navigationTitle("Régime Général")
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

struct ModelRetirementAgircView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ModelRetirementAgircView()
            .preferredColorScheme(.dark)
            .environmentObject(dataStoreTest)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
    }
}
