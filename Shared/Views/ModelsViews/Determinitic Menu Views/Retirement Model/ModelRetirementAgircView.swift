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

// MARK: - Deterministic Retirement Régime Complémentaire View

struct ModelRetirementAgircView: View {
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var isExpandedMajoration   : Bool = false
    @State private var alertItem              : AlertItem?
    
    var body: some View {
        Form {
            Section {
                VersionEditableView(version: $viewModel.retirementModel.regimeAgirc.model.version)
                    .onChange(of: viewModel.retirementModel.regimeAgirc.model.version) { _ in viewModel.isModified = true }
            }
            
            Stepper(value : $viewModel.retirementModel.regimeAgirc.ageMinimum,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum de liquidation")
                    Spacer()
                    Text("\(viewModel.retirementModel.regimeAgirc.ageMinimum) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.retirementModel.regimeAgirc.ageMinimum) { _ in viewModel.isModified = true }
            
            AmountEditView(label  : "Valeur du point",
                           amount : $viewModel.retirementModel.regimeAgirc.valeurDuPoint)
                .onChange(of: viewModel.retirementModel.regimeAgirc.valeurDuPoint) { _ in viewModel.isModified = true }
            
            NavigationLink(destination: AgircAvantAgeLegalGridView(label: "Réduction pour trimestres manquant avant l'âge légale",
                                                                   grid: $viewModel.retirementModel.regimeAgirc.gridAvantAgeLegal)
                            .environmentObject(viewModel)) {
                Text("Réduction pour trimestres manquant avant l'âge légale")
            }.isDetailLink(true)

            NavigationLink(destination: AgircApresAgeLegalGridView(label: "Réduction pour trimestres manquant après l'âge légale",
                                                                   grid: $viewModel.retirementModel.regimeAgirc.gridApresAgelegal)
                            .environmentObject(viewModel)) {
                Text("Réduction pour trimestres manquant après l'âge légale")
            }.isDetailLink(true)

            Section(header: Text("Majoration pour Enfants").font(.headline)) {
                Stepper(value : $viewModel.retirementModel.regimeAgirc.majorationPourEnfant.majorPourEnfantsNes,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants nés")
                        Spacer()
                        Text("\(viewModel.retirementModel.regimeAgirc.majorationPourEnfant.majorPourEnfantsNes.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.retirementModel.regimeAgirc.majorationPourEnfant.majorPourEnfantsNes) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.retirementModel.regimeAgirc.majorationPourEnfant.nbEnafntNesMin,
                        in    : 1 ... 4,
                        step  : 1) {
                    HStack {
                        Text("Nombre d'enfants nés pour obtenir la majoration")
                        Spacer()
                        Text("\(viewModel.retirementModel.regimeAgirc.majorationPourEnfant.nbEnafntNesMin) enfants").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.retirementModel.regimeAgirc.majorationPourEnfant.nbEnafntNesMin) { _ in viewModel.isModified = true }
                
                AmountEditView(label   : "Plafond pour enfants nés",
                               comment : "annuel",
                               amount  : $viewModel.retirementModel.regimeAgirc.majorationPourEnfant.plafondMajoEnfantNe)
                    .onChange(of: viewModel.retirementModel.regimeAgirc.majorationPourEnfant.plafondMajoEnfantNe) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.retirementModel.regimeAgirc.majorationPourEnfant.majorParEnfantACharge,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants à charge")
                        Spacer()
                        Text("\(viewModel.retirementModel.regimeAgirc.majorationPourEnfant.majorParEnfantACharge.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.retirementModel.regimeAgirc.majorationPourEnfant.majorParEnfantACharge) { _ in viewModel.isModified = true }
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

struct ModelRetirementAgircView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return ModelRetirementAgircView()
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
    }
}
