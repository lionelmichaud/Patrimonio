//
//  SuccessorGroupBox.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 29/04/2021.
//

import SwiftUI

struct SuccessorsListView: View {
    var inheritances : [Inheritance]

    var body: some View {
        List {
            ForEach(inheritances, id: \.person.id) { inheritence in
                SuccessorGroupBox(inheritence: inheritence)
            }
        }
        .navigationTitle("Héritage")
        .navigationBarTitleDisplayMode(.inline)

    }
}

struct SuccessorGroupBox : View {
    var inheritence: Inheritance

    var body: some View {
        GroupBox(label: groupBoxLabel(person: inheritence.person).font(.headline)) {
            Group {
                //                PercentView(label   : "Part de la succession",
                //                            percent : inheritence.percent)
                AmountView(label  : "Valeur héritée brute",
                           amount : inheritence.brut,
                           comment: inheritence.percent.percentStringRounded + " de la succession")
                    .padding(.top, 3)
                AmountView(label  : "Droits de succession à payer",
                           amount : -inheritence.tax,
                           comment: (inheritence.tax / inheritence.brut).percentStringRounded)
                    .padding(.top, 3)
                Divider()
                AmountView(label : "Valeur héritée nette",
                           amount: inheritence.net)
            }
            .foregroundColor(.secondary)
        }
    }

    func groupBoxLabel(person: Person) -> some View {
        HStack {
            Text(person.displayName)
            Spacer()
            Text(person is Adult ? "Conjoint" : "Enfant")
        }
    }
}

struct SuccessorGroupBox_Previews: PreviewProvider {
    static let inheritence = Inheritance(person: Person(sexe: .male,
                                                        givenName: "Lionel",
                                                        familyName: "Michaud",
                                                        birthDate: Date.now),
                                         percent: 100.0,
                                         brut: 1,
                                         net: 2,
                                         tax: 3)
    static var previews: some View {
        SuccessorGroupBox(inheritence: inheritence)
    }
}
