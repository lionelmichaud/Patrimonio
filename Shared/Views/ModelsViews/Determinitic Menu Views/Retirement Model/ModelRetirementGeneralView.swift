//
//  ModelRetirementGeneralView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import ModelEnvironment
import FamilyModel

// MARK: - Deterministic Retirement Régime General View

struct ModelRetirementGeneralView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            Section {
                VersionEditableView(version: $viewModel.retirementModel.regimeGeneral.model.version)
                    .onChange(of: viewModel.retirementModel.regimeGeneral.model.version) { _ in viewModel.isModified = true }
            }
            
            Stepper(value : $viewModel.retirementModel.regimeGeneral.ageMinimumLegal,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum légal de liquidation")
                    Spacer()
                    Text("\(viewModel.retirementModel.regimeGeneral.ageMinimumLegal) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.retirementModel.regimeGeneral.ageMinimumLegal) { _ in viewModel.isModified = true }

            NavigationLink(destination: DureeRefGridView(label: "Durée de référence",
                                                         grid: $viewModel.retirementModel.regimeGeneral.dureeDeReferenceGrid)
                            .environmentObject(viewModel)) {
                Text("Durée de référence")
            }.isDetailLink(true)

            NavigationLink(destination: NbTrimUnemployementGridView(label: "Trimestres pour chômage non indemnisé",
                                                                    grid: $viewModel.retirementModel.regimeGeneral.nbTrimNonIndemniseGrid)
                            .environmentObject(viewModel)) {
                Text("Trimestres pour chômage non indemnisé")
            }.isDetailLink(true)

            Stepper(value : $viewModel.retirementModel.regimeGeneral.maxReversionRate,
                    in    : 50 ... 100,
                    step  : 1.0) {
                HStack {
                    Text("Taux maximum")
                    Spacer()
                    Text("\(viewModel.retirementModel.regimeGeneral.maxReversionRate.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.retirementModel.regimeGeneral.maxReversionRate) { _ in viewModel.isModified = true }

            Section(header: Text("Décote / Surcote").font(.headline)) {
                Stepper(value : $viewModel.retirementModel.regimeGeneral.decoteParTrimestre,
                        in    : 0 ... 1.5,
                        step  : 0.025) {
                    HStack {
                        Text("Décote par trimestre manquant")
                        Spacer()
                        Text("\(viewModel.retirementModel.regimeGeneral.decoteParTrimestre.percentString(digit: 3)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.retirementModel.regimeGeneral.decoteParTrimestre) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.retirementModel.regimeGeneral.surcoteParTrimestre,
                        in    : 0 ... 2.5,
                        step  : 0.25) {
                    HStack {
                        Text("Surcote par trimestre supplémentaire")
                        Spacer()
                        Text("\(viewModel.retirementModel.regimeGeneral.surcoteParTrimestre.percentString(digit: 2)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.retirementModel.regimeGeneral.surcoteParTrimestre) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.retirementModel.regimeGeneral.maxNbTrimestreDecote,
                        in    : 10 ... 30,
                        step  : 1) {
                    HStack {
                        Text("Nombre de trimestres maximum de décote")
                        Spacer()
                        Text("\(viewModel.retirementModel.regimeGeneral.maxNbTrimestreDecote) trimestres").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.retirementModel.regimeGeneral.maxNbTrimestreDecote) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.retirementModel.regimeGeneral.majorationTauxEnfant,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour trois enfants nés")
                        Spacer()
                        Text("\(viewModel.retirementModel.regimeGeneral.majorationTauxEnfant.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.retirementModel.regimeGeneral.majorationTauxEnfant) { _ in viewModel.isModified = true }
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
        .navigationTitle("Régime Général")
    }
}

struct ModelRetirementGeneralView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelRetirementGeneralView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
