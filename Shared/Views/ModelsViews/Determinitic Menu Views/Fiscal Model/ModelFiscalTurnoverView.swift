//
//  ModelFiscalTurnoverView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalTurnoverView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: TurnoverTaxesModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            Stepper(value : $subModel.URSSAF,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("URSAAF")
                    Spacer()
                    Text("\(subModel.URSSAF.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Bénéfices Non Commerciaux (BNC)")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalTurnoverView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalTurnoverView(updateDependenciesToModel: { },
                                       subModel: .init(source: TestEnvir.model.fiscalModel.turnoverTaxes.model))
            .preferredColorScheme(.dark)
    }
}
