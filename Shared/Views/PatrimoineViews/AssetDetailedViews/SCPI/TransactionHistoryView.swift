//
//  TransactionHistoryView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 12/04/2022.
//

import SwiftUI
import AssetsModel
import HelpersView

struct TransactionHistoryView: View {
    var transactionHistory: TransactionHistory

    var body: some View {
        if transactionHistory.isEmpty {
            Text("Aucune transaction")
        } else {
            List(transactionHistory) { transac in
                GroupBox("Transaction") {
                    VStack {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(transac.date.stringLongDate)
                        }
                        .padding(.top, 4)
                        IntegerView(label: "Prix unitaire d'acquisition",
                                    integer: transac.quantity)
                        .padding(.top, 4)
                        AmountView(label: "Quantité",
                                   amount: transac.unitPrice)
                        .padding(.top, 4)
                        AmountView(label: "Montant de la transaction",
                                   amount: transac.amount)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                    .padding(.leading)
                }
            }
        }
    }
}

struct TransactionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionHistoryView(transactionHistory: TransactionHistory())
    }
}
