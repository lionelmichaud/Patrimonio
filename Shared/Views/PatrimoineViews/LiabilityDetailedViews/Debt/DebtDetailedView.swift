//
//  DebtDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Liabilities
import HelpersView

struct DebtDetailedView: View {
    let updateDependenciesToModel : () -> Void
    @Transac var item : Debt

    var body: some View {
        Form {
            LabeledTextField(label: "Nom",
                             defaultText: "obligatoire",
                             text: $item.name)
            .foregroundColor(item.name.isEmpty ? .red : .primary)
            LabeledTextEditor(label: "Note", text: $item.note)

            /// propriété
            OwnershipView(ownership  : $item.ownership,
                          totalValue : item.value(atEndOf : CalendarCst.thisYear))

            /// acquisition
            Section(header: Text("CARCTERISTIQUES")) {
                AmountEditView(label  : "Montant de la dette à date",
                               amount : $item.value)
                .foregroundColor(item.value > 0 ? .red : .primary)
                if item.value > 0 {
                    Label("Le montant emprunté doit être négatif", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .padding(.trailing)
                }
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("Dette")
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $item,
                             isValid                   : isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }

    private var isValid: Bool {
        /// vérifier que la valeure est négative ou nulle
        guard item.value.isNOZ else {
            return false
        }
        /// vérifier que le nom n'est pas vide
        guard item.name != "" else {
            return false
        }
        /// vérifier que les propriétaires sont correctements définis
        guard item.ownership.isValid else {
            return false
        }
        return true
    }
}

struct DebtDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return
            NavigationView {
                DebtDetailedView(updateDependenciesToModel: { },
                                 item: .init(source: TestEnvir.patrimoine.liabilities.debts.items.first!))
                EmptyView()
            }
            .previewDisplayName("DebtDetailedView")
    }
}
