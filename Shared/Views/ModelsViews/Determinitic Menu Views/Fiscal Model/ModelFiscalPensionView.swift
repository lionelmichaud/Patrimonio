//
//  ModelFiscalPensionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalPensionView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: PensionTaxesModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            Section {
                Stepper(value : $subModel.rebate,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(subModel.rebate.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }

                AmountEditView(label    : "Abattement minimum",
                               amount   : $subModel.minRebate,
                               validity : .poz)

                AmountEditView(label    : "Abattement maximum",
                               amount   : $subModel.maxRebate,
                               validity : .poz)
            } header: {
                Text("Abattement").font(.headline)
            }
            
            Section {
                Stepper(value : $subModel.CSGdeductible,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("CSG déductible")
                        Spacer()
                        Text("\(subModel.CSGdeductible.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

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

                Stepper(value : $subModel.additionalContrib,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Contribution additionnelle")
                        Spacer()
                        Text("\(subModel.additionalContrib.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.healthInsurance,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cotisation Assurance Santé")
                        Spacer()
                        Text("\(subModel.healthInsurance.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Taux de Cotisation").font(.headline)
            }
        }
        .navigationTitle("Plus-Value Immobilière")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalPensionView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalPensionView(updateDependenciesToModel: { },
                               subModel: .init(source: TestEnvir.model.fiscalModel.pensionTaxes.model))
            .preferredColorScheme(.dark)
    }
}
