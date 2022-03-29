//
//  ModelDeterministicHumanView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import AppFoundation
import HumanLifeModel
import HelpersView

// MARK: - Deterministic HumanLife View

struct ModelDeterministicHumanView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: HumanLife.Model
    @State private var alertItem: AlertItem?
    
    var body: some View {
        Form {
            Section(header: Text("Homme").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.menLifeExpectation.version)

                Stepper(value : $subModel.menLifeExpectation.defaultValue,
                        in    : 50 ... 100) {
                    HStack {
                        Text("Espérance de vie d'un Homme")
                        Spacer()
                        Text("\(Int(subModel.menLifeExpectation.defaultValue)) ans").foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Femme").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.womenLifeExpectation.version)

                Stepper(value : $subModel.womenLifeExpectation.defaultValue,
                        in    : 50 ... 100) {
                    HStack {
                        Text("Espérance de vie d'une Femme")
                        Spacer()
                        Text("\(Int(subModel.womenLifeExpectation.defaultValue)) ans").foregroundColor(.secondary)
                    }
                }
            }

            Section(header: Text("Dépendance").font(.headline)) {
                VersionEditableViewInForm(version: $subModel.nbOfYearsOfdependency.version)

                Stepper(value : $subModel.nbOfYearsOfdependency.defaultValue,
                        in    : 0 ... 10) {
                    HStack {
                        Text("Nombre d'années de dépendance")
                        Spacer()
                        Text("\(Int(subModel.nbOfYearsOfdependency.defaultValue)) ans").foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Modèle Humain")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelDeterministicHumanView_Previews: PreviewProvider {
    static var previews: some View {
        ModelDeterministicHumanView(updateDependenciesToModel: { },
                                    subModel: .init(source: TestEnvir.model.humanLifeModel))
        .preferredColorScheme(.dark)
    }
}
