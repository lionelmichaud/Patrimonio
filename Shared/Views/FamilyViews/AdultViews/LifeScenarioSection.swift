//
//  LifeScenarioSection.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 09/07/2022.
//

import SwiftUI
import ModelEnvironment
import PersonModel
import HelpersView

// MARK: - MemberDetailView / AdultDetailView / ScenarioSectionView

struct LifeScenarioSection: View {
    @EnvironmentObject private var model : Model
    var adult : Adult

    var body: some View {
        Section {
                DisclosureGroup {
                    LabeledText(label: "Age de décès estimé",
                                text : "\(adult.ageOfDeath) ans en \(String(adult.yearOfDeath))")
                    LabeledText(label: "Cessation d'activité",
                                text : "\(adult.age(atDate: adult.dateOfRetirement).year!) ans \(adult.age(atDate: adult.dateOfRetirement).month!) mois au \(adult.dateOfRetirement.stringMediumDate))")
                    LabeledText(label: "Cause",
                                text : adult.causeOfRetirement.displayString)
                    .padding(.leading)
                    if adult.hasUnemployementAllocationPeriod {
                        if let date = adult.dateOfStartOfUnemployementAllocation(using: model) {
                            LabeledText(label: "Début de la période d'allocation chômage",
                                        text : "\(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois au \(date.stringMediumDate)")
                            .padding(.leading)
                        }
                        if let date = adult.dateOfStartOfAllocationReduction(using: model) {
                            LabeledText(label: "Début de la période de réduction d'allocation chômage",
                                        text : "\(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois au \(date.stringMediumDate)")
                            .padding(.leading)
                        }
                        if let date = adult.dateOfEndOfUnemployementAllocation(using: model) {
                            LabeledText(label: "Fin de la période d'allocation chômage",
                                        text : "\(adult.age(atDate: date).year!) ans \(adult.age(atDate: date).month!) mois au \(date.stringMediumDate)")
                            .padding(.leading)
                        }
                    }
                    LabeledText(label: "Liquidation de pension - régime complém.",
                                text : "\(adult.ageOfAgircPensionLiquidComp.year!) ans \(adult.ageOfAgircPensionLiquidComp.month!) mois fin \(adult.dateOfAgircPensionLiquid.stringMediumMonth) \(String(adult.dateOfAgircPensionLiquid.year))")
                    LabeledText(label: "Liquidation de pension - régime général",
                                text : "\(adult.ageOfPensionLiquidComp.year!) ans \(adult.ageOfPensionLiquidComp.month!) mois fin \(adult.dateOfPensionLiquid.stringMediumMonth) \(String(adult.dateOfPensionLiquid.year))")
                    HStack {
                        Text("Dépendance")
                        Spacer()
                        if adult.nbOfYearOfDependency == 0 {
                            Text("aucune")
                        } else {
                            Text("\(adult.nbOfYearOfDependency) ans à partir de \(String(adult.yearOfDependency))")
                        }
                    }
                    NavigationLink(destination: PersonLifeLineView(from: self.adult, using: model)) {
                        Text("Ligne de vie").foregroundColor(.blue)
                    }
                } label: {
                    Text("SCENARIO DE VIE").font(.headline)
                }
        }
    }
}

struct LifeScenarioSection_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        let member = TestEnvir.family.members[0]
        // child
        return Form {
            LifeScenarioSection(adult: member as! Adult)
                .environmentObject(TestEnvir.model)
        }
    }
}

