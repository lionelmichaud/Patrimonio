//
//  ModelHumanView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import HumanLifeModel
import ModelEnvironment
import HelpersView

struct ModelStatisticHumanView: View {
    let updateDependenciesToModel: ( ) -> Void
    @EnvironmentObject private var model: Model
    @State private var alertItem: AlertItem?
    @State private var modelChoice: HumanLife.RandomVariable = .menLifeExpectation
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $modelChoice, label: "")
                .padding(.horizontal)
                .pickerStyle(.segmented)
            
            switch modelChoice {
                case .menLifeExpectation:
                    DiscreteRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                               discreteRandomizer: $model.humanLifeModel.menLifeExpectation.transaction())

                case .womenLifeExpectation:
                    DiscreteRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                               discreteRandomizer: $model.humanLifeModel.womenLifeExpectation.transaction())

                case .nbOfYearsOfdependency:
                    DiscreteRandomizerEditView(updateDependenciesToModel: updateDependenciesToModel,
                                               discreteRandomizer: $model.humanLifeModel.nbOfYearsOfdependency.transaction())
            }
        }
        .navigationTitle("Modèle Humain")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModelHumanView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelStatisticHumanView(updateDependenciesToModel: { })
        .environmentObject(TestEnvir.model)
        .preferredColorScheme(.dark)
    }
}
