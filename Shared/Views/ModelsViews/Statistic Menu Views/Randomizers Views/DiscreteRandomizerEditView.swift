//
//  DiscreteRandomizerEditView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 01/02/2022.
//

import SwiftUI
import ModelEnvironment
import Statistics

struct DiscreteRandomizerEditView: View {
    @EnvironmentObject private var model : Model
    @Binding var discreteRandomizer: ModelRandomizer<DiscreteRandomGenerator>
    
    var body: some View {
        VStack(alignment: .leading) {
            // édition de la version
            VersionEditableViewInForm(version: $discreteRandomizer.version)
                .frame(maxHeight: discreteRandomizer.version.comment == nil ? 30 : 60)
                .padding(.leading)
            
            // édition des paramètres de la loi discrète
            NavigationLink(destination: PointGridView(label: "Probability Density Function",
                                                      grid: $discreteRandomizer.rndGenerator.pdf),
                           label: {
                            Text("Editer la distribution statistique")
                                .padding([.leading, .top])
                           })
            
            // graphique
            DiscreteRandomizerView(randomizer: discreteRandomizer)
        }
    }
}

struct DiscreteRandomizerEditView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return DiscreteRandomizerEditView(discreteRandomizer: .constant(modelTest.socioEconomyModel.nbTrimTauxPlein))
    }
}
