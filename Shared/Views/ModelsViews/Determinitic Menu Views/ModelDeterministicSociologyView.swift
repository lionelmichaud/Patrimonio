//
//  ModelDeterministicSociologyView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import AppFoundation
import SocioEconomyModel
import HelpersView

// MARK: - Deterministic SocioEconomy View

struct ModelDeterministicSociologyView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: SocioEconomy.RandomizersModel
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Dévaluation des pensions").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.pensionDevaluationRate.version)

                Stepper(value : $subModel.pensionDevaluationRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Évolution anuelle des pensions de retraite")
                        Spacer()
                        Text("\(subModel.pensionDevaluationRate.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Évolution du nombre de trimestres requis").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.nbTrimTauxPlein.version)

                Stepper(value : $subModel.nbTrimTauxPlein.defaultValue,
                        in    : 0 ... 12) {
                    HStack {
                        Text("Nombre de trimestres additionels pour obtenir le taux plein")
                        Spacer()
                        Text("\(Int(subModel.nbTrimTauxPlein.defaultValue)) ans")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Sous-estimation du niveau des dépenses").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.expensesUnderEvaluationRate.version)
                
                Stepper(value : $subModel.expensesUnderEvaluationRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Pénalisation des dépenses")
                        Spacer()
                        Text("\(subModel.expensesUnderEvaluationRate.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: subModel.expensesUnderEvaluationRate) { _ in
                    updateDependenciesToModel()
                }
            }
        }
        .navigationTitle("Modèle Sociologique")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelDeterministicSociologyView_Previews: PreviewProvider {
    static var previews: some View {
        ModelDeterministicSociologyView(updateDependenciesToModel: { },
                                        subModel: .init(source: TestEnvir.model.socioEconomy.model!.randomizers))
            .preferredColorScheme(.dark)
    }
}
