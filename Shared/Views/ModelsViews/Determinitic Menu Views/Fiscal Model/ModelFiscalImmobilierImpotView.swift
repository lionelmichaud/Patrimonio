//
//  ModelFiscalImmobilierImpot.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalImmobilierImpotView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: RealEstateCapitalGainIrppModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $subModel.version)
            }
            
            NavigationLink(destination: RealEstateExonerationGridView(label: "Barême de l'Impôts sur Plus-Values Immobilières",
                                                                      grid: $subModel.exoGrid.transaction(),
                                                                      updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Barême de l'Impôts sur Plus-Values Immobilières")
            }.isDetailLink(true)

            Stepper(value : $subModel.irpp,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Taux d'impôt sur les plus-values")
                    Spacer()
                    Text("\(subModel.irpp.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Abattement").font(.headline)) {
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

                IntegerEditView(label   : "Abattement possible après",
                                comment : "ans",
                                integer : $subModel.discountAfter)
            }
        }
        .navigationTitle("Plus-Value Immobilière")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalImmobilierImpot_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalImmobilierImpotView(updateDependenciesToModel: { },
                                       subModel: .init(source: TestEnvir.model.fiscalModel.estateCapitalGainIrpp.model))
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
