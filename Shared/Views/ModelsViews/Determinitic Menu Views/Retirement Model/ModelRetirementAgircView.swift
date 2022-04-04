//
//  ModelRetirementAgircView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import RetirementModel
import HelpersView

// MARK: - Deterministic Retirement Régime Complémentaire View

struct ModelRetirementAgircView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: RegimeAgirc.Model
    @State private var alertItem: AlertItem?
    @State private var isExpandedMajoration: Bool = true
    
    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $subModel.version)
            }
            
            Stepper(value : $subModel.ageMinimum,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum de liquidation")
                    Spacer()
                    Text("\(subModel.ageMinimum) ans").foregroundColor(.secondary)
                }
            }

            AmountEditView(label  : "Valeur du point",
                           amount : $subModel.valeurDuPoint)

            NavigationLink(destination: AgircAvantAgeLegalGridView(label: "Réduction pour trimestres manquant avant l'âge légale",
                                                                   grid: $subModel.gridAvantAgeLegal.transaction(),
                                                                   updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Réduction pour trimestres manquant avant l'âge légale")
            }.isDetailLink(true)

            NavigationLink(destination: AgircApresAgeLegalGridView(label: "Réduction pour trimestres manquant après l'âge légale",
                                                                   grid: $subModel.gridApresAgelegal.transaction(),
                                                                   updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Réduction pour trimestres manquant après l'âge légale")
            }.isDetailLink(true)

            Section {
                Stepper(value : $subModel.majorationPourEnfant.majorPourEnfantsNes,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants nés")
                        Spacer()
                        Text("\(subModel.majorationPourEnfant.majorPourEnfantsNes.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.majorationPourEnfant.nbEnafntNesMin,
                        in    : 1 ... 4,
                        step  : 1) {
                    HStack {
                        Text("Nombre d'enfants nés pour obtenir la majoration")
                        Spacer()
                        Text("\(subModel.majorationPourEnfant.nbEnafntNesMin) enfants")
                            .foregroundColor(.secondary)
                    }
                }

                AmountEditView(label   : "Plafond pour enfants nés",
                               comment : "annuel",
                               amount  : $subModel.majorationPourEnfant.plafondMajoEnfantNe)

                Stepper(value : $subModel.majorationPourEnfant.majorParEnfantACharge,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants à charge")
                        Spacer()
                        Text("\(subModel.majorationPourEnfant.majorParEnfantACharge.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("Majoration pour Enfants").font(.headline)
            }
        }
        .navigationTitle("Régime Général")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelRetirementAgircView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ModelRetirementAgircView(updateDependenciesToModel: { },
                                        subModel: .init(source: TestEnvir.model.retirementModel.regimeAgirc.model))
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.simulation)
    }
}
