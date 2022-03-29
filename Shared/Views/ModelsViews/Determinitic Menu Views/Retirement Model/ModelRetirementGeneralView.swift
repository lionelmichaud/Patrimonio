//
//  ModelRetirementGeneralView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import RetirementModel
import HelpersView

// MARK: - Deterministic Retirement Régime General View

struct ModelRetirementGeneralView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: RegimeGeneral.Model
    @State private var alertItem: AlertItem?

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $subModel.version)
            }
            
            Stepper(value : $subModel.ageMinimumLegal,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum légal de liquidation")
                    Spacer()
                    Text("\(subModel.ageMinimumLegal) ans").foregroundColor(.secondary)
                }
            }

            NavigationLink(destination: DureeRefGridView(label: "Durée de référence",
                                                         grid: $subModel.dureeDeReferenceGrid.transaction(),
                                                         updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Durée de référence")
            }.isDetailLink(true)

            NavigationLink(destination: NbTrimUnemployementGridView(label: "Trimestres pour chômage non indemnisé",
                                                                    grid: $subModel.nbTrimNonIndemniseGrid.transaction(),
                                                                    updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Trimestres pour chômage non indemnisé")
            }.isDetailLink(true)

            Stepper(value : $subModel.maxReversionRate,
                    in    : 50 ... 100,
                    step  : 1.0) {
                HStack {
                    Text("Taux maximum")
                    Spacer()
                    Text("\(subModel.maxReversionRate.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Décote / Surcote").font(.headline)) {
                Stepper(value : $subModel.decoteParTrimestre,
                        in    : 0 ... 1.5,
                        step  : 0.025) {
                    HStack {
                        Text("Décote par trimestre manquant")
                        Spacer()
                        Text("\(subModel.decoteParTrimestre.percentString(digit: 3))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.surcoteParTrimestre,
                        in    : 0 ... 2.5,
                        step  : 0.25) {
                    HStack {
                        Text("Surcote par trimestre supplémentaire")
                        Spacer()
                        Text("\(subModel.surcoteParTrimestre.percentString(digit: 2))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.maxNbTrimestreDecote,
                        in    : 10 ... 30,
                        step  : 1) {
                    HStack {
                        Text("Nombre de trimestres maximum de décote")
                        Spacer()
                        Text("\(subModel.maxNbTrimestreDecote) trimestres")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.majorationTauxEnfant,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour trois enfants nés")
                        Spacer()
                        Text("\(subModel.majorationTauxEnfant.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Régime Général")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelRetirementGeneralView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelRetirementGeneralView(updateDependenciesToModel: { },
                                          subModel: .init(source: TestEnvir.model.retirementModel.regimeGeneral.model))
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
