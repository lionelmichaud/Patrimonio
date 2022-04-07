//
//  ModelUnemploymentDelayView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import AppFoundation
import UnemployementModel
import HelpersView

struct ModelUnemploymentAmountView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: UnemploymentCompensation.AmountModel
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            Section {
                Stepper(value : $subModel.case1Rate,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cas 1: % du salaire journalier de référence")
                        Spacer()
                        Text("\(subModel.case1Rate.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
                
                AmountEditView(label    : "Cas 1  : Indemnité journalière",
                               amount   : $subModel.case1Fix,
                               validity : .poz)
            } header: {
                Text("Cas n°1").font(.headline)
            }

            Section {
                Stepper(value : $subModel.case2Rate,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Cas 2: % du salaire journalier de référence")
                        Spacer()
                        Text("\(subModel.case2Rate.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Cas n°2").font(.headline)
            } footer: {
                Text("Le cas le plus favorable au demandeur d'emploi est retenu")
            }

            Section {
                AmountEditView(label    : "Allocation minimale",
                               amount   : $subModel.minAllocationEuro,
                               validity : .poz)

                AmountEditView(label    : "Allocation maximale",
                               amount   : $subModel.maxAllocationEuro,
                               validity : .poz)

                Stepper(value : $subModel.maxAllocationPcent,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Allocation maximale en % du salaire journalier de référence")
                        Spacer()
                        Text("\(subModel.maxAllocationPcent.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Limites").font(.headline)
            }
        }
        .navigationTitle("Calcul du montant de l'indemnité de recherche d'emploi")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelUnemploymentDelayView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelUnemploymentAmountView(updateDependenciesToModel: { },
                                           subModel: .init(source: TestEnvir.model.unemploymentModel.allocationChomage.model.amountModel))
        .preferredColorScheme(.dark)
    }
}
