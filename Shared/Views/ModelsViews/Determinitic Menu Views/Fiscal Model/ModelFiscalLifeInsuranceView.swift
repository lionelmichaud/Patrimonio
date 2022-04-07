//
//  ModelFiscalLifeInsuranceView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalLifeInsuranceView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: LifeInsuranceTaxes.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            AmountEditView(label   : "Abattement par personne",
                           comment : "annuel",
                           amount  : $subModel.rebatePerPerson,
                           validity: .poz)
        }
        .navigationTitle("Revenus d'Assurance Vie")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalLifeInsuranceView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelFiscalLifeInsuranceView(updateDependenciesToModel: { },
                                            subModel: .init(source: TestEnvir.model.fiscalModel.lifeInsuranceTaxes.model))
            .preferredColorScheme(.dark)
    }
}
