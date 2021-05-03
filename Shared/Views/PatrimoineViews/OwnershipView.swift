//
//  OwnershipView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct OwnershipView: View {
    @EnvironmentObject var family : Family
    @Binding var ownership        : Ownership
    var totalValue                : Double
    let usufruitierStr  = "Usufruitier"
    let proprietaireStr = "Propriétaire"
    let nuPropStr       = "Nu-Propriétaire"

    var body: some View {
        Section(header: Text("PROPRIETE")) {
            Toggle("Démembrement de propriété", isOn: $ownership.isDismembered)
            
            if ownership.isDismembered {
                /// démembrement de propriété
                Group {
                    NavigationLink(destination: OwnersListView(title  : usufruitierStr,
                                                               owners : $ownership.usufructOwners).environmentObject(family)) {
                        if ownership.isValid {
                            AmountView(label   : usufruitierStr+"s",
                                       amount  : (try! ownership.demembrementPercentage(atEndOf : Date.now.year).usufructPercent / 100.0) * totalValue,
                                       comment : try! ownership.demembrementPercentage(atEndOf : Date.now.year).usufructPercent.percentString(digit : 2)+"%")
                                .foregroundColor(.blue)
                        } else {
                            if !ownership.usufructOwners.isEmpty && ownership.usufructOwners.isvalid {
                                Text(usufruitierStr+"s").foregroundColor(.blue)
                            } else {
                                Text(usufruitierStr+"s").foregroundColor(.red)
                            }
                        }
                    }
                    NavigationLink(destination: OwnersListView(title  : nuPropStr,
                                                               owners : $ownership.bareOwners).environmentObject(family)) {
                        if ownership.isValid {
                            AmountView(label   : nuPropStr+"s",
                                       amount  : (try! ownership.demembrementPercentage(atEndOf : Date.now.year).bareValuePercent / 100.0) * totalValue,
                                       comment : try! ownership.demembrementPercentage(atEndOf : Date.now.year).bareValuePercent.percentString(digit : 2)+"%")
                                .foregroundColor(.blue)
                        } else {
                            if !ownership.bareOwners.isEmpty && ownership.bareOwners.isvalid {
                                Text(nuPropStr+"s").foregroundColor(.blue)
                            } else {
                                Text(nuPropStr+"s").foregroundColor(.red)
                            }
                        }
                    }
                }.padding(.leading)
                
            } else {
                /// pleine propriété
                NavigationLink(destination: OwnersListView(title  : proprietaireStr,
                                                           owners : $ownership.fullOwners).environmentObject(family)) {
                    Text(proprietaireStr+"s")
                        .foregroundColor(ownership.isValid ? .blue : .red)
                }.padding(.leading)
            }
        }
    }
}

struct OwnershipView_Previews: PreviewProvider {
    static var family  = Family()

    static func ageOf(_ name: String, _ year: Int) -> Int {
        let person = family.member(withName: name)
        return person?.age(atEndOf: Date.now.year) ?? -1
    }
    
    struct Container: View {
        @State var ownership  : Ownership
        @State var totalValue : Double = 100.0

        var body: some View {
            VStack {
                Button("incrémenter Valeur", action: { totalValue += 100.0})
                Form {
                    OwnershipView(ownership: $ownership, totalValue: totalValue)
                        .environmentObject(family)
                    ForEach(OwnershipView_Previews.family.members) { member in
                        AmountView(label: member.displayName,
                                   amount: ownership.ownedValue(by     : member.displayName,
                                                                ofValue: 100.0,
                                                                atEndOf: Date.now.year,
                                                                evaluationMethod: .ifi) )
                    }
                }
            }
        }
    }
    
    static var previews: some View {
        Group {
            //NavigationView {
                Form {
                    OwnershipView(ownership: .constant(Ownership(ageOf: ageOf)), totalValue: 1000.0)
                        .environmentObject(family)
                }
            //}
            .previewDevice("iPhone Xs")
            
            NavigationView {
                Container(ownership: Ownership(ageOf: ageOf))
            }
            .preferredColorScheme(.dark)
        }
    }
}
