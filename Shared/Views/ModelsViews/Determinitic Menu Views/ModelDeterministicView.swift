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
    @Published var menLifeExpectation   : Int
    @Published var womenLifeExpectation : Int

    // MARK: - Initialization
    
    init(using model: Model) {
        menLifeExpectation   = Int(model.humanLifeModel.menLifeExpectation.defaultValue)
        womenLifeExpectation = Int(model.humanLifeModel.womenLifeExpectation.defaultValue)
        isModified = false
    }

    // MARK: - methods
    
    func update(model: Model) {
        model.humanLife.model?.menLifeExpectation.defaultValue   = menLifeExpectation.double()
        model.humanLife.model?.womenLifeExpectation.defaultValue = womenLifeExpectation.double()
        isModified = false
    }
}

// MARK: - Deterministic View

/// Affiche les valeurs déterministes retenues pour les paramètres des modèles dans une simulation "déterministe"
struct ModelDeterministicView: View {
    private let model: Model // reference sur le modèle
    @StateObject private var viewModel: DeterministicViewModel
    let initialViewModel: DeterministicViewModel

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Modèle Humain")) {
                    IntegerEditView(label   : "Espérance de vie d'un Homme",
                                    integer : $viewModel.menLifeExpectation)
                        .onChange(of: viewModel.menLifeExpectation) { _ in viewModel.isModified = true }
                    IntegerEditView(label   : "Espérance de vie d'une Femme",
                                    integer : $viewModel.womenLifeExpectation)
                        .onChange(of: viewModel.womenLifeExpectation) { _ in viewModel.isModified = true }
                    IntegerView(label   : "Nombre d'années de dépendance",
                                integer : Int(model.humanLifeModel.nbOfYearsOfdependency.defaultValue))
                }
                Section(header: Text("Modèle Economique")) {
                    PercentView(label   : "Inflation",
                                percent : Economy.model.randomizers.inflation.value(withMode: .deterministic)/100.0)
                    PercentView(label   : "Rendement sans Risque",
                                percent : Economy.model.randomizers.securedRate.value(withMode: .deterministic)/100.0)
                    PercentView(label   : "Rendement des Actions",
                                percent : Economy.model.randomizers.stockRate.value(withMode: .deterministic)/100.0)
                }
                Section(header: Text("Modèle Sociologique")) {
                    PercentView(label   : "Dévaluation anuelle des pensions par rapport à l'inflation",
                                percent : -SocioEconomy.model.pensionDevaluationRate.value(withMode: .deterministic)/100.0)
                    IntegerView(label   : "Nombre de trimestres additionels pour obtenir le taux plein",
                                integer : Int(SocioEconomy.model.nbTrimTauxPlein.value(withMode: .deterministic)))
                    PercentView(label   : "Pénalisation des dépenses",
                                percent : SocioEconomy.model.expensesUnderEvaluationRate.value(withMode: .deterministic)/100.0)
                }
            }
            .navigationTitle("Modèle Déterministe")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(
                        action : applyChanges,
                        label  : {
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .imageScale(.large)
                                Text("Enregistrer")
                            }
                        })
                        .capsuleButtonStyle()
                        .disabled(!viewModel.isModified)
                }
            }
        }
    }
    
    // MARK: - Initialization
    
    init(using model: Model) {
        self.model = model
        let viewModel = DeterministicViewModel(using: model)
        initialViewModel = viewModel
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - methods
    
    func applyChanges() {
        viewModel.update(model: model)
    }
}

struct ModelDeterministicView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        ModelDeterministicView(using: model)
    }
}
