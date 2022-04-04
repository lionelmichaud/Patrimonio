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

struct FreeInvestDetailedView: View {
    @EnvironmentObject var model  : Model
    let updateDependenciesToModel : () -> Void
    @Transac var item : FreeInvestement

    @State private var totalValue : Double = 0.0

    var body: some View {
        Form {
            LabeledTextField(label       : "Nom",
                             defaultText : "obligatoire",
                             text        : $item.name,
                             validity    : .notEmpty)
            LabeledTextEditor(label: "Note", text: $item.note)
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
                AmountEditView(label    : "Valeure actualisée",
                               amount   : $totalValue,
                               validity : .poz)
                    .onChange(of: totalValue) { newValue in
                        item.lastKnownState.investment = newValue - item.lastKnownState.interest
                    }
                AmountEditView(label: "dont plus-values",
                               amount: $item.lastKnownState.interest)
                    .onChange(of: item.lastKnownState.interest) { newValue in
                        item.lastKnownState.investment = totalValue - newValue
                    }
            } header: {
                Text("INITIALISATION")
            }
            
            Section {
                InterestRateTypeEditView(rateType: $item.interestRateType)
                PercentView(label   : "Rendement moyen net d'inflation",
                            percent : item.averageInterestRateNetOfTaxesAndInflation)
                    .foregroundColor(.secondary)
            } header: {
                Text("RENTABILITE")
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