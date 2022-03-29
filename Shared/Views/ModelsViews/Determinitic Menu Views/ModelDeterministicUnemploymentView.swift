//
//  ModelDeterministicUnemploymentView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import UnemployementModel
import HelpersView

struct ModelDeterministicUnemploymentView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: UnemploymentCompensation.Model
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            NavigationLink(destination:
                            UnemploymentAreDurationGridView(label: "Barême de durée d'indemnisation",
                                                            grid: $subModel.durationGrid.transaction(),
                                                            updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Durée d'indemnisation")
            }.isDetailLink(true)

            NavigationLink(destination: ModelUnemploymentDiffereView(updateDependenciesToModel: updateDependenciesToModel,
                                                                     subModel: $subModel.delayModel.transaction())) {
                Text("Différés d'indemnisation")
            }

            NavigationLink(destination: ModelUnemploymentAmountView(updateDependenciesToModel: updateDependenciesToModel,
                                                                    subModel: $subModel.amountModel.transaction())) {
                Text("Allocation de Recherche d'Emploi (ARE)")
            }
        }
        .navigationTitle("Modèle Chômage")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelDeterministicUnemploymentView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelDeterministicUnemploymentView(updateDependenciesToModel: { },
                                                  subModel: .init(source: TestEnvir.model.unemploymentModel.allocationChomage.model))
            .preferredColorScheme(.dark)
    }
}
