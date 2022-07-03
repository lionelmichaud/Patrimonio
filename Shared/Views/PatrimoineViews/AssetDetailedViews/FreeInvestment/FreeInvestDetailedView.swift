//
//  FreeInvestView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import ModelEnvironment
import AssetsModel
import HelpersView

//public struct LabelTextEditor : View {
//    let label      : String
//    let labelWidth : Int
//    let validity   : StringValidityRule
//    @Binding
//    var text       : String
//
//    public var body: some View {
//        HStack {
//            Text(label)
//                .frame(width: Double(labelWidth), alignment: .leading)
//            if #available(iOS 16.0, macOS 13.0, *) {
//            TextField("Note", text: $text, axis: .vertical)
//                .lineLimit(5)
//                .textFieldStyle(.roundedBorder)
//            } else {
//                TextEditor(text: $text)
//                    .textFieldStyle(.roundedBorder)
//            }
//        }
//        .foregroundColor(validity.isValid(text: text) ? .primary : .red)
//    }
//
//    public init(label       : String,
//                labelWidth  : Int = 70,
//                text        : Binding<String>,
//                validity    : StringValidityRule = .none) {
//        self.label       = label
//        self.labelWidth  = labelWidth > 0 ? labelWidth : 70
//        self.validity    = validity
//        self._text       = text
//    }
//}

struct FreeInvestDetailedView: View {
    @EnvironmentObject var model  : Model
    let updateDependenciesToModel : () -> Void
    @Transac var item : FreeInvestement

    private var totalValue : Binding<Double> {
        Binding(
            get: {
                item.lastKnownState.value
            },
            set: {
                // ajuster le montant de l'investissement en conséquence
                item.lastKnownState.investment = $0 - item.lastKnownState.interest
            }
        )
    }

    private var interests : Binding<Double> {
        Binding(
            get: {
                item.lastKnownState.interest
            },
            set: {
                // ajuster le montant de l'investissement en conséquence
                item.lastKnownState.investment = item.lastKnownState.value - $0
                item.lastKnownState.interest = $0
            }
        )
    }

    var body: some View {
        Form {
            LabeledTextField(label       : "Nom",
                             defaultText : "obligatoire",
                             text        : $item.name,
                             validity    : .notEmpty)
            LabeledTextEditor(label: "Note",
                              text: $item.note
            )
            WebsiteEditView(website: $item.website)

            /// propriété
            OwnershipView(ownership  : $item.ownership,
                          totalValue : item.value(atEndOf  : CalendarCst.thisYear))

            Section {
                TypeInvestEditView(investType: $item.type)
            } header: {
                Text("TYPE")
            }

            Section {
                YearPicker(title    : "Année d'actualisation",
                           inRange  : CalendarCst.thisYear - 20...CalendarCst.thisYear + 100,
                           selection: $item.lastKnownState.year)
                AmountEditView(label    : "Valeure totale actualisée",
                               amount   : totalValue,
                               validity : .poz)
                AmountEditView(label: "dont plus-values",
                               amount: interests).padding(.leading)
            } header: {
                Text("VALEUR ACTUALISÉE")
            }

            Section {
                InterestRateTypeEditView(rateType: $item.interestRateType)
                PercentView(label   : "Rendement moyen net d'inflation",
                            percent : item.averageInterestRateNetOfTaxesAndInflation)
                    .foregroundColor(.secondary)
            } header: {
                Text("RENTABILITE")
            }

            Section {
                NavigationLink(destination: SimulationRachatView(item: item)) {
                    Text("Rachat")
                }
                .isDetailLink(true)
            } header: {
                Text("SIMULATION DE RACHAT")
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("Invest. Libre")
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $item,
                             isValid                   : item.isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct FreeInvestDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
            FreeInvestDetailedView(updateDependenciesToModel: { },
                                   item: .init(source: TestEnvir.patrimoine.assets.freeInvests.items.first!))
        }
        .previewDisplayName("FreeInvestDetailedView")
    }
}
