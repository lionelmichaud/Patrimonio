//
//  ModelFiscalImpotSocieteView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalImpotSocieteView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: CompanyProfitTaxesModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            Stepper(value : $subModel.rate,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Taux d'impôt sur les bénéfices")
                    Spacer()
                    Text("\(subModel.rate.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Bénéfice des Sociétés (IS)")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalImpotSocieteView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalImpotSocieteView(updateDependenciesToModel: { },
                                    subModel: .init(source: TestEnvir.model.fiscalModel.companyProfitTaxes.model))
            .preferredColorScheme(.dark)
    }
}
