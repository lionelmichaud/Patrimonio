//
//  ModelUnemploymentAmountView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import AppFoundation
import UnemployementModel
import HelpersView

struct ModelUnemploymentDiffereView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: UnemploymentCompensation.DelayModel
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Délai").font(.headline)) {
                Stepper(value : $subModel.delaiAttente,
                        in    : 0 ... 100) {
                    HStack {
                        Text("Délai d'attente avant inscription")
                        Spacer()
                        Text("\(subModel.delaiAttente) jours")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Différé Spécifique").font(.headline)) {
                Stepper(value : $subModel.ratioDiffereSpecifique,
                        in    : 0 ... 100.0,
                        step  : 0.1) {
                    HStack {
                        Text("Nombre de jours de différé obtenu en x le montant de l'indemnité par ce coefficient")
                        Spacer()
                        Text("\(subModel.ratioDiffereSpecifique.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.maxDiffereSpecifique,
                        in    : 0 ... 300) {
                    HStack {
                        Text("Durée maximale du différé spécifique")
                        Spacer()
                        Text("\(subModel.maxDiffereSpecifique) jours")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.maxDiffereSpecifiqueLicenciementEco,
                        in    : 0 ... 150) {
                    HStack {
                        Text("Sauf dans le cas d'un licenciement économique")
                        Spacer()
                        Text("\(subModel.maxDiffereSpecifiqueLicenciementEco) jours")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Calcul du Différé d'indemnisation")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelUnemploymentAmountView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelUnemploymentDiffereView(updateDependenciesToModel: { },
                                            subModel: .init(source: TestEnvir.model.unemploymentModel.allocationChomage.model.delayModel))
            .preferredColorScheme(.dark)
    }
}
