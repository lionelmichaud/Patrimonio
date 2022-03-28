//
//  ModelRetirementReversionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import Persistence
import RetirementModel
import HelpersView

// MARK: - Deterministic Retirement Pension de Réversion View

struct ModelRetirementReversionView : View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: PensionReversion.Model
    @State private var alertItem: AlertItem?
    @State private var isExpandedCurrentGeneral : Bool = true
    @State private var isExpandedCurrentAgirc   : Bool = true

    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $subModel.version)
            }
            
            Toggle("Utiliser la réforme des retraites",
                   isOn: $subModel.newModelSelected)

            Section(header: Text("Système Réformé Futur").font(.headline)) {
                Stepper(value : $subModel.tauxReversion,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Taux de réversion")
                        Spacer()
                        Text("\(subModel.tauxReversion.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Système Actuel").font(.headline)) {
                DisclosureGroup("Régime Général",
                                isExpanded: $isExpandedCurrentGeneral) {
                    AmountEditView(label: "Minimum",
                                   amount: $subModel.oldModel.general.minimum)

                    Stepper(value : $subModel.oldModel.general.majoration3enfants,
                            in    : 0 ... 100.0,
                            step  : 1.0) {
                        HStack {
                            Text("Majoration pour 3 enfants nés")
                            Spacer()
                            Text("\(subModel.oldModel.general.majoration3enfants.percentString(digit: 0))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                DisclosureGroup("Régime Complémentaire",
                                isExpanded: $isExpandedCurrentAgirc) {
                    Stepper(value : $subModel.oldModel.agircArcco.ageMinimum,
                            in    : 50 ... 100) {
                        HStack {
                            Text("Age minimum pour perçevoir la pension de réversion")
                            Spacer()
                            Text("\(subModel.oldModel.agircArcco.ageMinimum) ans")
                                .foregroundColor(.secondary)
                        }
                    }

                    Stepper(value : $subModel.oldModel.agircArcco.fractionConjoint,
                            in    : 0 ... 100.0,
                            step  : 1.0) {
                        HStack {
                            Text("Fraction des points du conjoint décédé")
                            Spacer()
                            Text("\(subModel.oldModel.agircArcco.fractionConjoint.percentString(digit: 0))")
                                .foregroundColor(.secondary)
                        }
                    }

                }
            }
        }
        .navigationTitle("Régime Général")
        .alert(item: $alertItem, content: newAlert)
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelRetirementReversionView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelRetirementReversionView(updateDependenciesToModel: { },
                                            subModel: .init(source: TestEnvir.model.retirementModel.reversion.model))
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
