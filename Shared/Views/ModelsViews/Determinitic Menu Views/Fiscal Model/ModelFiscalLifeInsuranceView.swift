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

            Section {
                AmountEditView(label   : "Abattement par personne",
                               comment : "annuel",
                               amount  : $subModel.rebatePerPerson,
                               validity: .poz)
                Stepper(value : $subModel.prelevementLiberatoire,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Prélèvement Liberatoire")
                        Spacer()
                        Text("\(subModel.prelevementLiberatoire.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            header: {
                Text("Imposition")
            }
            footer: {
                Text("Avant \(subModel.datePivot.formatted(.dateTime.day().month(.abbreviated).year()))")
            }

            Section {
                AmountEditView(label   : "Seuil d'imposition à la flat tax",
                               comment : "après la date de transition",
                               amount  : $subModel.seuil,
                               validity: .poz)
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
            footer: {
                Text("Après \(subModel.datePivot.formatted(.dateTime.month(.narrow).day().year(.twoDigits)))")
            }
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
