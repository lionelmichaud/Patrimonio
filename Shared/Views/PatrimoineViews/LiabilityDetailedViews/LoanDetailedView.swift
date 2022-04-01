//
//  LoanDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Liabilities
import HelpersView

struct LoanDetailedView: View {
    let updateDependenciesToModel : () -> Void
    @Transac var item : Loan

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
            
            // acquisition
            Section(header: Text("CARCTERISTIQUES")) {
                AmountEditView(label  : "Montant emprunté",
                               amount : $item.loanedValue)
                .foregroundColor(item.loanedValue > 0 ? .red : .primary)
                YearPicker(title     : "Première année (inclue)",
                           inRange   : CalendarCst.thisYear - 20 ... min(item.lastYear, CalendarCst.thisYear + 50),
                           selection : $item.firstYear)
                YearPicker(title     : "Dernière année (inclue)",
                           inRange   : max(item.firstYear, CalendarCst.thisYear - 20) ... CalendarCst.thisYear + 50,
                           selection : $item.lastYear)
                LabeledText(label: "Durée du prêt",
                                text : "\(item.lastYear - item.firstYear + 1) ans")
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("CONDITIONS")) {
                PercentEditView(label   : "Taux d'intérêt annuel",
                                percent : $item.interestRate)
                .foregroundColor(item.interestRate < 0 ? .red : .primary)
                AmountEditView(label  : "Montant mensuel de l'assurance",
                               amount : $item.monthlyInsurance)
                .foregroundColor(item.monthlyInsurance < 0 ? .red : .primary)
                AmountView(label  : "Remboursement annuel (de janvier \(item.firstYear) à décembre \(item.lastYear))",
                           amount : item.yearlyPayement(item.firstYear))
                    .foregroundColor(.secondary)
                AmountView(label  : "Remboursement mensuel (de janvier \(item.firstYear) à décembre \(item.lastYear))",
                           amount : item.yearlyPayement(item.firstYear)/12.0)
                    .foregroundColor(.secondary)
                AmountView(label  : "Remboursement restant (au 31/12/\(CalendarCst.thisYear))",
                           amount : item.value(atEndOf: CalendarCst.thisYear))
                    .foregroundColor(.secondary)
                AmountView(label  : "Remboursement total",
                           amount : item.totalPayement)
                    .foregroundColor(.secondary)
                AmountView(label  : "Coût total du crédit",
                           amount : item.costOfCredit)
                    .foregroundColor(.secondary)
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("Emprunt")
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $item,
                             isValid                   : isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }
    
    private var isValid: Bool {
        if item.loanedValue > 0 {
            return false
        }
        if item.interestRate < 0 {
            return false
        }
        if item.monthlyInsurance < 0 {
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

struct LoanDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
                LoanDetailedView(updateDependenciesToModel: { },
                                 item: .init(source: TestEnvir.patrimoine.liabilities.loans.items.first!))
                EmptyView()
            }
            .previewDisplayName("LoanDetailedView")
    }
}
