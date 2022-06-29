//
//  ModelFiscalFinancialView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalFinancialView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: FinancialRevenuTaxesModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            Section {
                Stepper(value : $subModel.CRDS,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CRDS")
                        Spacer()
                        Text("\(subModel.CRDS.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.CSG,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CSG")
                        Spacer()
                        Text("\(subModel.CSG.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.prelevSocial,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Prélèvement Sociaux")
                        Spacer()
                        Text("\(subModel.prelevSocial.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            header: {
                Text("Charges sociales")
            }
            footer: {
                Text("Appliquable à tous les revenus financiers")
            }

            Section {
                Stepper(value : $subModel.flatTax,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Flat Tax")
                        Spacer()
                        Text("\(subModel.flatTax.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            header: {
                Text("Imposition")
            }
            footer: {
                Text("Appliquable à tous les revenus financiers")
            }
        }
        .navigationTitle("Revenus Financiers")
        .alert(item: $alertItem, content: newAlert)
    /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                             updateDependenciesToModel : updateDependenciesToModel)
}
}

struct ModelFiscalFinancialView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelFiscalFinancialView(updateDependenciesToModel: { },
                                        subModel: .init(source: TestEnvir.model.fiscalModel.financialRevenuTaxes.model))
        .preferredColorScheme(.dark)
    }
}
