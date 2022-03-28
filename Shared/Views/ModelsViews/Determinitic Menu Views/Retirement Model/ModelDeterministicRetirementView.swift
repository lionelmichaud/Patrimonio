//
//  ModelDeterministicRetirementView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import Persistence
import ModelEnvironment
import FamilyModel
import HelpersView
import SimulationAndVisitors

// MARK: - Deterministic Retirement View

struct ModelDeterministicRetirementView: View {
    let updateDependenciesToModel: ( ) -> Void
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        Form {
            NavigationLink(destination: ModelRetirementGeneralView(updateDependenciesToModel: updateDependenciesToModel,
                                                                   subModel: $model.retirementModel.regimeGeneral.model.transaction())) {
                Text("Pension du Régime Général")
                Spacer()
                VersionVStackView(version: model.retirementModel.regimeGeneral.model.version,
                            withDetails: false)
            }
            
            NavigationLink(destination: ModelRetirementAgircView(updateDependenciesToModel: updateDependenciesToModel,
                                                                 subModel: $model.retirementModel.regimeAgirc.model.transaction())) {
                Text("Pension du Régime Complémentaire")
                Spacer()
                VersionVStackView(version: model.retirementModel.regimeAgirc.model.version,
                            withDetails: false)
            }
            
            NavigationLink(destination: ModelRetirementReversionView(updateDependenciesToModel: updateDependenciesToModel,
                                                                     subModel: $model.retirementModel.reversion.model.transaction())) {
                Text("Pension de Réversion")
                Spacer()
                VersionVStackView(version: model.retirementModel.reversion.model.version,
                            withDetails: false)
            }
        }
        .navigationTitle("Modèle Retraite")
        .alert(item: $alertItem, content: newAlert)
    }
}

struct ModelDeterministicRetirementView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelDeterministicRetirementView(updateDependenciesToModel: { })
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
            .preferredColorScheme(.dark)
    }
}
