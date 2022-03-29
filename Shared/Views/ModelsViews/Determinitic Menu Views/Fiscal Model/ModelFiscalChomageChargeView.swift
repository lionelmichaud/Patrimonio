//
//  ModelFiscalChomageChargeView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalChomageChargeView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: AllocationChomageTaxesModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $subModel.version)
            }
            
            Stepper(value : $subModel.assiette,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("Assiette")
                    Spacer()
                    Text("\(subModel.assiette.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }

            AmountEditView(label  : "Seuil de Taxation CSG/CRDS",
                           comment: "journalier",
                           amount : $subModel.seuilCsgCrds)

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

            Stepper(value : $subModel.retraiteCompl,
                    in    : 0 ... 100.0,
                    step  : 0.1) {
                HStack {
                    Text("Cotisation de Retraite Complémentaire")
                    Spacer()
                    Text("\(subModel.retraiteCompl.percentString(digit: 1))")
                        .foregroundColor(.secondary)
                }
            }

            AmountEditView(label  : "Seuil de Taxation Retraite Complémentaire",
                           comment: "journalier",
                           amount : $subModel.seuilRetCompl)
        }
        .navigationTitle("Allocation Chômage")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalChomageChargeView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalChomageChargeView(updateDependenciesToModel: { },
                                     subModel: .init(source: TestEnvir.model.fiscalModel.allocationChomageTaxes.model))
            .preferredColorScheme(.dark)
    }
}
