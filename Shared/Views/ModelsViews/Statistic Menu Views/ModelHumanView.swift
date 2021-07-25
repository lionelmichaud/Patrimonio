//
//  ModelHumanView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import HumanLifeModel

struct ModelHumanView: View {
    @EnvironmentObject var model: Model
    @State private var modelChoice: HumanLife.RandomVariable = .menLifeExpectation
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
            switch modelChoice {
                case .menLifeExpectation:
                    DiscreteRandomizerView(randomizer: model.humanLifeModel.menLifeExpectation)
                
                case .womenLifeExpectation:
                    DiscreteRandomizerView(randomizer: model.humanLifeModel.womenLifeExpectation)
                
                case .nbOfYearsOfdependency:
                    DiscreteRandomizerView(randomizer: model.humanLifeModel.nbOfYearsOfdependency)
            }
        }
        .navigationTitle("Modèle Humain: Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelHumanView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    
    static var previews: some View {
        ModelHumanView()
            .environmentObject(model)
    }
}
