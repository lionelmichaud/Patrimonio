//
//  InheritanceSection.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 10/07/2022.
//

import SwiftUI
import ModelEnvironment
import PersonModel
import HelpersView
import PatrimoineModel
import SuccessionManager
import Succession

// MARK: - MemberDetailView / AdultDetailView / InheritanceSectionView

struct InheritanceSection: View {
    @EnvironmentObject var model      : Model
    @EnvironmentObject var patrimoine : Patrimoin
    var adult: Adult

    var body: some View {
        Section {
            DisclosureGroup(
                content: {
                    inheritanceOptionDisclosureView(adult: adult)
                    deceaseDisclosure(decedent: adult)
                },
                label: {
                    Text("SUCCESSION LEGALE").font(.headline)
                })
        }
        //.onAppear(perform: { self.patrimoine.restore() })
    }

    // MARK: - Methods

    /// Option fiscale retenue en cas d'héritage
    /// - Parameter adult: défunt
    /// - Returns: DisclosureGroup
    func inheritanceOptionDisclosureView(adult: Adult) -> some View {
        DisclosureGroup(
            content: {
                LabeledText(label: "Option fiscale retenue",
                            text : adult.fiscalOption.displayString)
            },
            label: {
                Text("En cas d'héritage du conjoint").font(.headline)
            })
    }

    /// Héritage laissé en cas de décès à la date courante à l'age de décès estimé
    /// - Parameter adult: défunt
    /// - Returns: DisclosureGroup
    func deceaseDisclosure(decedent: Adult) -> some View {
        DisclosureGroup(
            content: {
                inheritanceDisclosure(label    : "A la date d'aujourd'hui",
                                      atEndOf  : Date.now.year,
                                      decedent : decedent)
                inheritanceDisclosure(label    : "A l'âge de décès estimé \(adult.ageOfDeath) ans en \(String(adult.yearOfDeath))",
                                      atEndOf  : adult.yearOfDeath,
                                      decedent : decedent)
            },
            label: {
                Text("En cas de décès").font(.headline)
            })
    }

    func inheritanceDisclosure(label        : String,
                               atEndOf year : Int,
                               decedent     : Adult) -> some View {
        let legalSuccessionManager = LegalSuccessionManager(using          : model.fiscalModel,
                                                            familyProvider : Patrimoin.familyProvider!,
                                                            atEndOf        : year)
        let succession = legalSuccessionManager.succession(of                 : decedent.displayName,
                                                           with               : patrimoine,
                                                           previousSuccession : nil)
        let taxableInheritanceValue = legalSuccessionManager.masseSuccessorale(in: patrimoine,
                                                                               of: decedent.displayName)

        return DisclosureGroup(
            content: {
                AmountView(label : "Masse successorale",
                           amount: taxableInheritanceValue)
                AmountView(label : "Droits de succession à payer par les héritiers",
                           amount: -succession.tax)
                AmountView(label : "Succession nette laissée aux héritiers",
                           amount: succession.netFiscal)
                NavigationLink(destination  : SuccessorsListView(successionKind: SuccessionKindEnum.legal,
                                                                 inheritances : succession.inheritances)) {
                    Text("Héritage")
                        .foregroundColor(.blue)
                }
            },
            label: {
                Text(label)
                    .font(.headline)
            })
    }
}

//struct InheritanceSectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestEnvir.loadTestFilesFromBundle()
//        let member = TestEnvir.familyTest.members[0]
//        // child
//        return Form {
//            InheritanceSectionView(member: member)
//                .environmentObject(TestEnvir.dataStoreTest)
//                .environmentObject(TestEnvir.modelTest)
//                .environmentObject(TestEnvir.uiStateTest)
//                .environmentObject(TestEnvir.familyTest)
//                .environmentObject(TestEnvir.expensesTest)
//                .environmentObject(TestEnvir.patrimoineTest)
//                .environmentObject(TestEnvir.simulationTest)
//        }
//    }
//}
