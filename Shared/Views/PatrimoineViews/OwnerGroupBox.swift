//
//  OwnerGroupBox.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 03/05/2021.
//

import SwiftUI
import Ownership

struct OwnerGroupBox: View {
    private let title        : String
    private let index        : Int
    @Binding var owners      : Owners
    @State private var owner : Owner
    
    var body: some View {
        GroupBox(label: Text(title)) {
            VStack {
                Label(owner.name, systemImage: "person.fill").padding(.top, 8)
                Stepper(value: $owner.fraction,
                        in: 0.0...100.0,
                        step: 5.0,
                        onEditingChanged: { started in
                            if !started {
                                // mettre à jour la liste contenant le owner pour forcer l'update de la View
                                owners[index].fraction = owner.fraction
                            }
                        },
                        label: {
                            Text("Fraction détenue: ") +
                                Text(String(owner.fraction) + "%")
                                .bold()
                                .foregroundColor(owners.percentageOk ? .blue : .red)
                        })
                    .frame(maxWidth: 300)
            }
            .padding(.leading)
        }
        .groupBoxStyle(DefaultGroupBoxStyle())
    }
    
    internal init(title              : String,
                  owner              : Owner,
                  owners             : Binding<Owners>) {
        self.title   = title
        self._owner  = State(initialValue : owner)
        self._owners = owners
        self.index   = owners.wrappedValue.firstIndex(of: owner)!
    }
}

struct OwnerGroupBox_Previews: PreviewProvider {
    static let goodOwner  = Owner(name : "Lionel Michaud", fraction : 100)
    static let goodOwners = [OwnersListView_Previews.goodOwner]

    static var previews: some View {
        OwnerGroupBox(title: "Usufruitier",
                      owner: goodOwner,
                      owners: .constant(goodOwners))
    }
}
