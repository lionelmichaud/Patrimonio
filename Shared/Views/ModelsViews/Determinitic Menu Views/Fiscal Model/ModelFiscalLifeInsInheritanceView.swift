//
//  ModelFiscalLifeInsInheritanceView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalLifeInsInheritanceView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: LifeInsuranceInheritance.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            NavigationLink(destination: RateGridView(label: "Barême Transmssion Assurance Vie",
                                                     grid: $subModel.grid.transaction(),
                                                     updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Barême Fiscal des Transmssions d'Assurance Vie")
            }.isDetailLink(true)
        }
        .navigationTitle("Transmission des Assurances Vie")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalLifeInsInheritanceView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalLifeInsInheritanceView(updateDependenciesToModel: { },
                                          subModel: .init(source: TestEnvir.model.fiscalModel.lifeInsuranceInheritance.model))
            .preferredColorScheme(.dark)
    }
}
