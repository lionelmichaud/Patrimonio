//
//  ModelFiscalImmobilierTaxeView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalImmobilierTaxeView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: RealEstateCapitalGainTaxesModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $subModel.version)
            }
            
            NavigationLink(destination: RealEstateExonerationGridView(label: "Barême des taxes sur Plus-Values Immobilières",
                                                                      grid: $subModel.exoGrid.transaction(),
                                                                      updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Barême des taxes sur Plus-Values Immobilières")
            }.isDetailLink(true)

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
                    Text("Prélèvements Sociaux")
                    Spacer()
                    Text("\(subModel.prelevSocial.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }

            Stepper(value : $subModel.discountTravaux,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Abattement forfaitaire pour travaux")
                    Spacer()
                    Text("\(subModel.discountTravaux.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }

            IntegerEditView(label    : "Abattement possible après",
                            comment  : "ans",
                            integer  : $subModel.discountAfter,
                            validity : .poz)
        }
        .navigationTitle("Plus-Value Immobilière")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalImmobilierTaxeView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalImmobilierTaxeView(updateDependenciesToModel: { },
                                      subModel: .init(source: TestEnvir.model.fiscalModel.estateCapitalGainTaxes.model))
        .preferredColorScheme(.dark)
    }
}
