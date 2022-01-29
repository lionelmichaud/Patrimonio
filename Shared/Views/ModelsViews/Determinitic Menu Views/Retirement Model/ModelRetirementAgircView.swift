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
            Stepper(value : $viewModel.ageMinimumAGIRC,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum de liquidation")
                    Spacer()
                    Text("\(viewModel.ageMinimumAGIRC) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.ageMinimumAGIRC) { _ in viewModel.isModified = true }
            
            AmountEditView(label  : "Valeur du point",
                           amount : $viewModel.valeurDuPointAGIRC)
                .onChange(of: viewModel.valeurDuPointAGIRC) { _ in viewModel.isModified = true }
            
            Section(header: Text("Majoration pour Enfants").font(.headline)) {
                Stepper(value : $viewModel.majorationPourEnfant.majorPourEnfantsNes,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants nés")
                        Spacer()
                        Text("\(viewModel.majorationPourEnfant.majorPourEnfantsNes.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.majorationPourEnfant.majorPourEnfantsNes) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.majorationPourEnfant.nbEnafntNesMin,
                        in    : 1 ... 4,
                        step  : 1) {
                    HStack {
                        Text("Nombre d'enfants nés pour obtenir la majoration")
                        Spacer()
                        Text("\(viewModel.majorationPourEnfant.nbEnafntNesMin) enfants").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.majorationPourEnfant.nbEnafntNesMin) { _ in viewModel.isModified = true }
                
                AmountEditView(label   : "Plafond pour enfants nés",
                               comment : "annuel",
                               amount  : $viewModel.majorationPourEnfant.plafondMajoEnfantNe)
                    .onChange(of: viewModel.majorationPourEnfant.plafondMajoEnfantNe) { _ in viewModel.isModified = true }
                
                Stepper(value : $viewModel.majorationPourEnfant.majorParEnfantACharge,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants à charge")
                        Spacer()
                        Text("\(viewModel.majorationPourEnfant.majorParEnfantACharge.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.majorationPourEnfant.majorParEnfantACharge) { _ in viewModel.isModified = true }
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
