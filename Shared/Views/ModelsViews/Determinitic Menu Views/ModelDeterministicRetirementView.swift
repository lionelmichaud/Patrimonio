//
//  ModelDeterministicRetirementView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import ModelEnvironment

// MARK: - Deterministic Retirement View

struct ModelDeterministicRetirementView: View {
    @ObservedObject var viewModel: DeterministicViewModel

    var body: some View {
        Section(header: Text("Modèle Retraite").font(.headline)) {
            ModelRetirementGeneralView()
                .environmentObject(viewModel)

            ModelRetirementAgircView()
                .environmentObject(viewModel)

            ModelRetirementReversionView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Deterministic Retirement General View

struct ModelRetirementGeneralView: View {
    @EnvironmentObject private var viewModel : DeterministicViewModel
    @State private var isExpanded     : Bool = false

    var body: some View {
        DisclosureGroup("Régime Général",
                        isExpanded: $isExpanded) {
            Stepper(value : $viewModel.ageMinimumLegal,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum légal de liquidation")
                    Spacer()
                    Text("\(viewModel.ageMinimumLegal) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.ageMinimumLegal) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.maxReversionRate,
                    in    : 50 ... 100,
                    step  : 1.0) {
                HStack {
                    Text("Taux maximum")
                    Spacer()
                    Text("\(viewModel.maxReversionRate.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.maxReversionRate) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.decoteParTrimestre,
                    in    : 0 ... 1.5,
                    step  : 0.025) {
                HStack {
                    Text("Décote par trimestre manquant")
                    Spacer()
                    Text("\(viewModel.decoteParTrimestre.percentString(digit: 3)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.decoteParTrimestre) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.surcoteParTrimestre,
                    in    : 0 ... 2.5,
                    step  : 0.25) {
                HStack {
                    Text("Surcote par trimestre supplémentaire")
                    Spacer()
                    Text("\(viewModel.surcoteParTrimestre.percentString(digit: 2)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.surcoteParTrimestre) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.maxNbTrimestreDecote,
                    in    : 10 ... 30,
                    step  : 1) {
                HStack {
                    Text("Nombre de trimestres maximum de décote")
                    Spacer()
                    Text("\(viewModel.maxNbTrimestreDecote) trimestres").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.maxNbTrimestreDecote) { _ in viewModel.isModified = true }

            Stepper(value : $viewModel.majorationTauxEnfant,
                    in    : 0 ... 20.0,
                    step  : 1.0) {
                HStack {
                    Text("Surcote pour trois enfants nés")
                    Spacer()
                    Text("\(viewModel.majorationTauxEnfant.percentString(digit: 0)) %").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.majorationTauxEnfant) { _ in viewModel.isModified = true }

        }
    }
}

// MARK: - Deterministic Retirement Complémentaire View

struct ModelRetirementAgircView: View {
    @EnvironmentObject private var viewModel : DeterministicViewModel
    @State private var isExpanded            : Bool = false
    @State private var isExpandedMajoration  : Bool = false

    var body: some View {
        DisclosureGroup("Régime Complémentaire",
                        isExpanded: $isExpanded) {
            Stepper(value : $viewModel.ageMinimumAGIRC,
                    in    : 50 ... 100) {
                HStack {
                    Text("Age minimum de liquidation")
                    Spacer()
                    Text("\(viewModel.ageMinimumAGIRC) ans").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.ageMinimumAGIRC) { _ in viewModel.isModified = true }

            AmountEditView(label: "Valeur du point", amount: $viewModel.valeurDuPointAGIRC)
                .onChange(of: viewModel.valeurDuPointAGIRC) { _ in viewModel.isModified = true }

            DisclosureGroup("Majoration pour Enfants",
                            isExpanded: $isExpandedMajoration) {
                Stepper(value : $viewModel.majorationPourEnfant.majorPourEnfantsNes,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants nés")
                        Spacer()
                        Text("\(viewModel.majorationPourEnfant.majorPourEnfantsNes.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.majorationPourEnfant.majorPourEnfantsNes) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.majorationPourEnfant.nbEnafntNesMin,
                        in    : 1 ... 4,
                        step  : 1) {
                    HStack {
                        Text("Nombre d'enfants nés pour obtenir la majoration")
                        Spacer()
                        Text("\(viewModel.majorationPourEnfant.nbEnafntNesMin) enfants").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.majorationPourEnfant.nbEnafntNesMin) { _ in viewModel.isModified = true }

                AmountEditView(label: "Plafond pour enfants nés", amount: $viewModel.majorationPourEnfant.plafondMajoEnfantNe)
                    .onChange(of: viewModel.majorationPourEnfant.plafondMajoEnfantNe) { _ in viewModel.isModified = true }

                Stepper(value : $viewModel.majorationPourEnfant.majorParEnfantACharge,
                        in    : 0 ... 20.0,
                        step  : 1.0) {
                    HStack {
                        Text("Surcote pour enfants à charge")
                        Spacer()
                        Text("\(viewModel.majorationPourEnfant.majorParEnfantACharge.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.majorationPourEnfant.majorParEnfantACharge) { _ in viewModel.isModified = true }
            }
        }
    }
}

struct ModelRetirementReversionView : View {
    @EnvironmentObject private var viewModel : DeterministicViewModel
    @State private var isExpanded               : Bool = false
    @State private var isExpandedCurrent        : Bool = false
    @State private var isExpandedCurrentGeneral : Bool = false
    @State private var isExpandedCurrentAgirc   : Bool = false
    @State private var isExpandedFutur          : Bool = false

    var body: some View {
        DisclosureGroup("Pension de Réversion",
                        isExpanded: $isExpanded) {
            Toggle("Utiliser la réforme des retraite",
                   isOn: $viewModel.newModelSelected)
                .onChange(of: viewModel.newModelSelected) { _ in viewModel.isModified = true }

            DisclosureGroup("Future Réforme",
                            isExpanded: $isExpandedFutur) {
                Stepper(value : $viewModel.newTauxReversion,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Taux de réversion")
                        Spacer()
                        Text("\(viewModel.newTauxReversion.percentString(digit: 0)) %").foregroundColor(.secondary)
                    }
                }.onChange(of: viewModel.newTauxReversion) { _ in viewModel.isModified = true }
            }
            
            DisclosureGroup("Système Actuel",
                            isExpanded: $isExpandedCurrent) {
                DisclosureGroup("Régime Général",
                                isExpanded: $isExpandedCurrentGeneral) {
                    AmountEditView(label: "Minimum", amount: $viewModel.oldReversionModel.general.minimum)
                        .onChange(of: viewModel.oldReversionModel.general.minimum) { _ in viewModel.isModified = true }
                    Stepper(value : $viewModel.oldReversionModel.general.majoration3enfants,
                            in    : 0 ... 100.0,
                            step  : 1.0) {
                        HStack {
                            Text("Majoration pour 3 enfants nés")
                            Spacer()
                            Text("\(viewModel.oldReversionModel.general.majoration3enfants.percentString(digit: 0)) %").foregroundColor(.secondary)
                        }
                    }.onChange(of: viewModel.oldReversionModel.general.majoration3enfants) { _ in viewModel.isModified = true }
                }
                DisclosureGroup("Régime Complémentaire",
                                isExpanded: $isExpandedCurrentAgirc) {
                    Stepper(value : $viewModel.oldReversionModel.agircArcco.ageMinimum,
                            in    : 50 ... 100) {
                        HStack {
                            Text("Age minimum pour perçevoir la pension de réversion")
                            Spacer()
                            Text("\(viewModel.oldReversionModel.agircArcco.ageMinimum) ans").foregroundColor(.secondary)
                        }
                    }.onChange(of: viewModel.oldReversionModel.agircArcco.ageMinimum) { _ in viewModel.isModified = true }
                    Stepper(value : $viewModel.oldReversionModel.agircArcco.fractionConjoint,
                            in    : 0 ... 100.0,
                            step  : 1.0) {
                        HStack {
                            Text("Fraction des points du conjoint décédé")
                            Spacer()
                            Text("\(viewModel.oldReversionModel.agircArcco.fractionConjoint.percentString(digit: 0)) %").foregroundColor(.secondary)
                        }
                    }.onChange(of: viewModel.oldReversionModel.agircArcco.fractionConjoint) { _ in viewModel.isModified = true }
                }
            }
        }
    }
}

struct ModelDeterministicRetirementView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)

    static var previews: some View {
        Form {
            ModelDeterministicRetirementView(viewModel: DeterministicViewModel(using: model))
        }
    }
}
