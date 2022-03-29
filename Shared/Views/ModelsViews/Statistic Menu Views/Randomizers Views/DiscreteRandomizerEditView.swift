//
//  DiscreteRandomizerEditView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 01/02/2022.
//

import SwiftUI
import AppFoundation
import ModelEnvironment
import Statistics
import HelpersView

struct DiscreteRandomizerEditView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var discreteRandomizer: ModelRandomizer<DiscreteRandomGenerator>
    
    var body: some View {
        VStack(alignment: .leading) {
            // édition de la version
            VersionEditableViewInForm(version: $discreteRandomizer.version)
                .frame(maxHeight: discreteRandomizer.version.comment == nil ? 30 : 60)
                .padding(.leading)
            
            // édition des paramètres de la loi discrète
            NavigationLink(destination: PointGridView(label: "Probability Density Function",
                                                      grid: $discreteRandomizer.rndGenerator.pdf.transaction(),
                                                      updateDependenciesToModel: updateDependenciesToModel),
                           label: {
                                Text("Editer la distribution statistique")
                                    .padding([.leading, .top])
                           })
            
            // graphique
            DiscreteRandomizerView(randomizer: discreteRandomizer)
        }
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $discreteRandomizer,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct DiscreteRandomizerEditView_Previews: PreviewProvider {
    static var previews: some View {
        DiscreteRandomizerEditView(updateDependenciesToModel: { },
                                   discreteRandomizer: .init(source: TestEnvir.model.socioEconomyModel.randomizers.nbTrimTauxPlein))
    }
}
