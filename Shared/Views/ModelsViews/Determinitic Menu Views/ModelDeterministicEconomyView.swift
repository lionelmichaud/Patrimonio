//
//  ModelDeterministicEconomyModel.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import AppFoundation
import Persistence
import ModelEnvironment
import EconomyModel
import HelpersView

// MARK: - Deterministic Economy View

struct ModelDeterministicEconomyView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: Economy.RandomizersModel
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            Section(header: Text("Inflation").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.inflation.version)

                Stepper(value : $subModel.inflation.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Inflation")
                        Spacer()
                        Text("\(subModel.inflation.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Placements sans Risque").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.securedRate.version)

                Stepper(value : $subModel.securedRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(subModel.securedRate.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.securedVolatility,
                        in    : 0 ... 5,
                        step  : 0.1) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(subModel.securedVolatility.percentString(digit: 2))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Placements Actions").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.stockRate.version)

                Stepper(value : $subModel.stockRate.defaultValue,
                        in    : 0 ... 10,
                        step  : 0.05) {
                    HStack {
                        Text("Rendement")
                        Spacer()
                        Text("\(subModel.stockRate.defaultValue.percentString(digit: 1))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.stockVolatility,
                        in    : 0 ... 20,
                        step  : 1.0) {
                    HStack {
                        Text("Volatilité")
                        Spacer()
                        Text("\(subModel.stockVolatility.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Modèle Economique")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelDeterministicEconomyView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelDeterministicEconomyView(updateDependenciesToModel: { },
                                             subModel: .init(source: TestEnvir.model.economy.model!.randomizers))
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
            .preferredColorScheme(.dark)
    }
}
