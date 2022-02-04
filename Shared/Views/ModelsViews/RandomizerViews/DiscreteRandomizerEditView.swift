//
//  DiscreteRandomizerEditView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 01/02/2022.
//

import SwiftUI
import ModelEnvironment

struct DiscreteRandomizerEditView: View {
    @EnvironmentObject private var model : Model

    var body: some View {
        DiscreteRandomizerView(randomizer: model.socioEconomyModel.nbTrimTauxPlein)
    }
}

struct DiscreteRandomizerEditView_Previews: PreviewProvider {
    static var previews: some View {
        DiscreteRandomizerEditView()
    }
}
