//
//  SuccessorGroupBox.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 29/04/2021.
//

import SwiftUI
import Succession
import PersonModel
import FamilyModel
import ModelEnvironment
import HelpersView

struct SuccessorsListView: View {
    var successionKind : SuccessionKindEnum
    var inheritances : [Inheritance]

    var body: some View {
        List {
            ForEach(inheritances, id: \.successorName) { inheritence in
                SuccessorGroupBox(successionKind : successionKind,
                                  inheritence    : inheritence)
            }
        }
        .navigationTitle("Héritiers")
        .navigationBarTitleDisplayMode(.inline)

    }
}

struct SuccessorGroupBox : View {
    var successionKind : SuccessionKindEnum
    var inheritence    : Inheritance
    @EnvironmentObject private var family: Family
    @EnvironmentObject private var model : Model
    
    var abattement: Double {
        switch successionKind {
            case .lifeInsurance:
                return model.fiscalModel.lifeInsuranceInheritance.abattement(fracAbattement: inheritence.abatFrac)
            case .legal:
                return model.fiscalModel.inheritanceDonation.model.abatLigneDirecte
        }
    }
    var abattementFraction: Double {
        switch successionKind {
            case .lifeInsurance:
                return inheritence.abatFrac
            case .legal:
                return 1.0
        }
    }

    var body: some View {
        GroupBox(
            content: {
                Group {
                    AmountView(label  : "Base taxable brute (évaluation fiscale)",
                               amount : inheritence.brutFiscal,
                               comment: inheritence.percentFiscal.percentStringRounded + " de la masse successorale")
                    .padding(.top, 3)
                    AmountView(label  : "Abattement fiscal",
                               amount : abattement,
                               comment: abattementFraction.percentStringRounded)
                    .padding(.top, 3)
                    AmountView(label  : "Droits de succession à payer",
                               amount : -inheritence.tax,
                               comment: (inheritence.tax / inheritence.brutFiscal).percentStringRounded)
                    .padding(.top, 3)
                    AmountView(label  : "Net (évaluation fiscale)",
                               amount : inheritence.netFiscal,
                               comment: "=")
                    .padding(.top, 3)
                    Divider()
                    AmountView(label  : "Héritage reçu brut (en cash)",
                               amount : inheritence.received)
                    AmountView(label  : "Héritage reçu net (en cash)",
                               amount : inheritence.receivedNet)
                    .padding(.top, 3)
                    AmountView(label  : "Créance de restitution de l'héritier envers le quasi-usufruitier",
                               amount : inheritence.creanceRestit)
                    .padding(.top, 3)
                }
                .foregroundColor(.secondary)
            },
            label: {
                groupBoxLabel(personName: inheritence.successorName).font(.headline)
            })
    }

    func groupBoxLabel(personName: String) -> some View {
        HStack {
            Text(personName)
            Spacer()
            Text(family.member(withName: personName) is Adult ? "Conjoint" : "Enfant")
        }
    }
}

struct SuccessorGroupBox_Previews: PreviewProvider {
    static let inheritence = Inheritance(personName    : "M. Lionel MICHAUD",
                                         percentFiscal : 100.0,
                                         brutFiscal    : 1,
                                         abatFrac      : 0.8,
                                         netFiscal     : 2,
                                         tax           : 3,
                                         received      : 2,
                                         receivedNet   : 1)
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return SuccessorGroupBox(successionKind : SuccessionKindEnum.lifeInsurance,
                                 inheritence    : inheritence)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
    }
}
