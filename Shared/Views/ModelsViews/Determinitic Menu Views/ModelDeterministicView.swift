//
//  ModelDeterministicView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Statistics
import HumanLifeModel
import EconomyModel
import SocioEconomyModel

// MARK: - Deterministic View

/// Affiche les valeurs déterministes retenues pour les paramètres des modèles dans une simulation "déterministe"
struct ModelDeterministicView: View {
    @EnvironmentObject private var dataStore : Store
    @EnvironmentObject private var model     : Model
    @EnvironmentObject private var family    : Family
    @StateObject private var viewModel       : DeterministicViewModel

    var body: some View {
        if dataStore.activeDossier != nil {
            VStack {
                Form {
                    // modèle vie humaine
                    ModelDeterministicHumanView(viewModel: viewModel)
                    
                    // modèle écnonomie
                    ModelDeterministicEconomyModel(viewModel: viewModel)
                    
                    // modèle sociologie
                    ModelDeterministicSociologyView(viewModel: viewModel)
                    
                    // modèle retraite
                    ModelDeterministicRetirementView(viewModel: viewModel)
                }
                .navigationTitle("Modèle Déterministe")
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        SaveToFolderButton(action : applyChanges)
                            .disabled(!changeOccured)
                    }
                }
            }
            .onAppear {
                viewModel.updateFrom(model)
            }
        } else {
            NoLoadedDossierView()
        }
    }
    
    // MARK: - Properties
    
    var changeOccured: Bool {
        viewModel.isModified
    }

    // MARK: - Initialization
    
    init(using model: Model) {
        _viewModel = StateObject(wrappedValue: DeterministicViewModel(using: model))
    }
    
    // MARK: - Methods
    
    func applyChanges() {
        // mettre à jour le modèle avec les nouvelles valeurs
        viewModel.update(model)

        // mettre à jour les membres de la famille existants
        viewModel.update(family)
    }
}

// MARK: - Deterministic HumanLife View

struct ModelDeterministicHumanView: View {
    @ObservedObject var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Humain")) {
            Stepper(value : $viewModel.menLifeExpectation,
                    in    : 50 ... 100) {
                HStack {
                    Text("Espérance de vie d'un Homme")
                    Spacer()
                    Text("\(viewModel.menLifeExpectation) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.menLifeExpectation) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.womenLifeExpectation,
                    in    : 50 ... 100) {
                HStack {
                    Text("Espérance de vie d'une Femme")
                    Spacer()
                    Text("\(viewModel.womenLifeExpectation) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.womenLifeExpectation) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.nbOfYearsOfdependency,
                    in    : 0 ... 10) {
                HStack {
                    Text("Nombre d'années de dépendance")
                    Spacer()
                    Text("\(viewModel.nbOfYearsOfdependency) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.nbOfYearsOfdependency) { _ in viewModel.isModified = true }
        }
    }
}

// MARK: - Deterministic Economy View

struct ModelDeterministicEconomyModel: View {
    @ObservedObject var viewModel: DeterministicViewModel
    
    var body: some View {
        return Section(header: Text("Modèle Economique")) {
            PercentEditView(label   : "Inflation",
                            percent : $viewModel.inflation)
            Stepper(value : $viewModel.inflation,
                    in    : 0 ... 12,
                    step  : 0.1) {
                HStack {
                    Text("Inflation")
                    Spacer()
                    Text("\(viewModel.inflation.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }
            .onChange(of: viewModel.inflation) { _ in viewModel.isModified = true }
            
            PercentEditView(label   : "Rendement sans Risque",
                            percent : $viewModel.securedRate)
                .onChange(of: viewModel.securedRate) { _ in viewModel.isModified = true }
            
            PercentEditView(label   : "Rendement des Actions",
                            percent : $viewModel.stockRate)
                .onChange(of: viewModel.stockRate) { _ in viewModel.isModified = true }
        }
    }
}

// MARK: - Deterministic SocioEconomy View

struct ModelDeterministicSociologyView: View {
    @ObservedObject var viewModel: DeterministicViewModel
    
    var body: some View {
        Section(header: Text("Modèle Sociologique")) {
            PercentEditView(label   : "Dévaluation anuelle des pensions par rapport à l'inflation",
                            percent : $viewModel.pensionDevaluationRate)
                .onChange(of: viewModel.pensionDevaluationRate) { _ in viewModel.isModified = true }
            
            Stepper(value : $viewModel.nbTrimTauxPlein,
                    in    : 0 ... 12) {
                HStack {
                    Text("Nombre de trimestres additionels pour obtenir le taux plein")
                    Spacer()
                    Text("\(viewModel.nbTrimTauxPlein) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.menLifeExpectation) { _ in viewModel.isModified = true }
            
            PercentEditView(label   : "Pénalisation des dépenses",
                            percent : $viewModel.expensesUnderEvaluationRate)
                .onChange(of: viewModel.expensesUnderEvaluationRate) { _ in viewModel.isModified = true }
        }
    }
}

// MARK: - Deterministic Retirement View

struct ModelDeterministicRetirementView: View {
    @ObservedObject var viewModel: DeterministicViewModel
    @State private var isExpanded: Bool = true

    var body: some View {
        Section(header: Text("Modèle Retraite")) {
            DisclosureGroup("Régime Général",
                            isExpanded: $isExpanded) {
                Stepper(value : $viewModel.ageMinimumLegal,
                        in    : 50 ... 100) {
                    HStack {
                        Text("Age minimum légal de liquidation")
                        Spacer()
                        Text("\(viewModel.ageMinimumLegal) ans").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.ageMinimumLegal) { _ in viewModel.isModified = true }
            }

            DisclosureGroup("Régime Complémentaire",
                            isExpanded: $isExpanded) {
                Stepper(value : $viewModel.ageMinimumAGIRC,
                        in    : 50 ... 100) {
                    HStack {
                        Text("Age minimum de liquidation")
                        Spacer()
                        Text("\(viewModel.ageMinimumAGIRC) ans").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.ageMinimumAGIRC) { _ in viewModel.isModified = true }

                AmountView(label  : "Valeur du point",
                           amount : viewModel.valeurDuPointAGIRC,
                           digit: 4)
            }
        }
    }
}

struct ModelDeterministicView_Previews: PreviewProvider {
    static let dataStore = Store()
    static var model     = Model(fromBundle : Bundle.main)
    static var family    = Family()

    static var previews: some View {
        dataStore.activate(dossierAtIndex: 0)
        return ModelDeterministicView(using: model)
            .environmentObject(model)
            .environmentObject(family)
    }
}
