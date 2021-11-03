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

struct SuccessorsListView: View {
    var inheritances : [Inheritance]

    var body: some View {
        List {
            ForEach(inheritances, id: \.successorName) { inheritence in
                SuccessorGroupBox(inheritence: inheritence)
            }
        }
        .navigationTitle("Héritage")
        .navigationBarTitleDisplayMode(.inline)

    }
}

struct SuccessorGroupBox : View {
    var inheritence: Inheritance
    @EnvironmentObject private var family: Family

    var body: some View {
        GroupBox(label: groupBoxLabel(personName: inheritence.successorName).font(.headline)) {
            Group {
                //                PercentView(label   : "Part de la succession",
                //                            percent : inheritence.percent)
                AmountView(label  : "Valeur héritée brute (évaluation fiscale)",
                           amount : inheritence.brutFiscal,
                           comment: inheritence.percentFiscal.percentStringRounded + " de la succession")
                    .padding(.top, 3)
                AmountView(label  : "Droits de succession à payer",
                           amount : -inheritence.tax,
                           comment: (inheritence.tax / inheritence.brutFiscal).percentStringRounded)
                    .padding(.top, 3)
                Divider()
                AmountView(label : "Valeur héritée nette (évaluation fiscale)",
                           amount: inheritence.netFiscal)
            }
            .foregroundColor(.secondary)
        }
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
    static let inheritence = Inheritance(personName: "M. Lionel MICHAUD",
                                         percent: 100.0,
                                         brut: 1,
                                         abatFrac: 0.8,
                                         net: 2,
                                         tax: 3)
    static var previews: some View {
        SuccessorGroupBox(inheritence: inheritence)
    }
}
