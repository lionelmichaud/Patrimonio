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

// MARK: - Deterministic View Model

class DeterministicViewModel: ObservableObject {

    // MARK: - Properties
    var isModified : Bool
    @Published var menLifeExpectation    : Int
    @Published var womenLifeExpectation  : Int
    @Published var nbOfYearsOfdependency : Int

    // MARK: - Initialization
    
    init(using model: Model) {
        menLifeExpectation    = model.humanLife.menLifeExpectationDeterministic
        womenLifeExpectation  = model.humanLife.womenLifeExpectationDeterministic
        nbOfYearsOfdependency = model.humanLife.nbOfYearsOfdependencyDeterministic
        isModified = false
    }

    // MARK: - methods
    
    func updateFrom(_ model: Model) {
        menLifeExpectation    = model.humanLife.menLifeExpectationDeterministic
        womenLifeExpectation  = model.humanLife.womenLifeExpectationDeterministic
        nbOfYearsOfdependency = model.humanLife.nbOfYearsOfdependencyDeterministic
    }
    
    func update(_ model: Model) {
        model.humanLife.menLifeExpectationDeterministic    = menLifeExpectation
        model.humanLife.womenLifeExpectationDeterministic  = womenLifeExpectation
        model.humanLife.nbOfYearsOfdependencyDeterministic = nbOfYearsOfdependency
        isModified = false
    }
}

// MARK: - Deterministic View

/// Affiche les valeurs déterministes retenues pour les paramètres des modèles dans une simulation "déterministe"
struct ModelDeterministicView: View {
    @EnvironmentObject private var model: Model
    //private let model: Model // reference sur le modèle
    @StateObject private var viewModel: DeterministicViewModel

    var body: some View {
        VStack {
            Form {
                // modèle vie humaine
                ModelDeterministicHumanView(viewModel: viewModel)
                
                // modèle écnonomie
                ModeldeterministicEconomyModel(viewModel: viewModel)

                // modèle sociologie
                ModelDeterministicSociologyView(viewModel: viewModel)
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
    }
    
    // MARK: - Properties
    
    var changeOccured: Bool {
        viewModel.isModified
    }

    // MARK: - Initialization
    
    init(using model: Model) {
//        self.model = model
        _viewModel = StateObject(wrappedValue: DeterministicViewModel(using: model))
    }
    
    // MARK: - Methods
    
    func applyChanges() {
        viewModel.update(model)
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

struct ModeldeterministicEconomyModel: View {
    @ObservedObject var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Economique")) {
            PercentView(label   : "Inflation",
                        percent : Economy.model.randomizers.inflation.value(withMode: .deterministic)/100.0)
            PercentView(label   : "Rendement sans Risque",
                        percent : Economy.model.randomizers.securedRate.value(withMode: .deterministic)/100.0)
            PercentView(label   : "Rendement des Actions",
                        percent : Economy.model.randomizers.stockRate.value(withMode: .deterministic)/100.0)
        }
    }
}

// MARK: - Deterministic SocioEconomy View

struct ModelDeterministicSociologyView: View {
    @ObservedObject var viewModel: DeterministicViewModel
    
    var body: some View {
        Section(header: Text("Modèle Sociologique")) {
            PercentView(label   : "Dévaluation anuelle des pensions par rapport à l'inflation",
                        percent : -SocioEconomy.model.pensionDevaluationRate.value(withMode: .deterministic)/100.0)
            IntegerView(label   : "Nombre de trimestres additionels pour obtenir le taux plein",
                        integer : Int(SocioEconomy.model.nbTrimTauxPlein.value(withMode: .deterministic)))
            PercentView(label   : "Pénalisation des dépenses",
                        percent : SocioEconomy.model.expensesUnderEvaluationRate.value(withMode: .deterministic)/100.0)
        }
    }
}

struct ModelDeterministicView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        ModelDeterministicView(using: model)
    }
}
