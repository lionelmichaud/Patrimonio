//
//  TransactionHistoryView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 12/04/2022.
//

import SwiftUI
import AppFoundation
import AssetsModel
import HelpersView

struct TransactionHistoryView: View {
    var transactionHistory: TransactionHistory

    var body: some View {
        if transactionHistory.isEmpty {
            Text("Aucune transaction")
        } else {
            List(transactionHistory) { transac in
                GroupBox {
                    VStack {
                        HStack {
                            Text("Date")
                            Spacer()
                            Text(transac.date.stringLongDate)
                        }
                        .padding(.top, 4)
                        IntegerView(label: "Quantité",
                                    integer: transac.quantity)
                        .padding(.top, 4)
                        AmountView(label: transac.quantity.isPOZ ? "Prix unitaire d'acquisition" : "Prix unitaire de vente",
                                   amount: transac.unitPrice)
                        .padding(.top, 4)
                        AmountView(label: "Montant de la transaction",
                                   amount: transac.amount)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    }
                    .padding(.leading)
                } label: {
                    if transac.quantity.isPOZ {
                        Text("\(Image(systemName: "plus.circle")) Achat")
                    } else {
                        Text("\(Image(systemName: "minus.circle")) Vente")
                    }
                }
            }
        }
    }
}

struct TransactionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionHistoryView(transactionHistory: [TransactionOrder(quantity: 10,
                                                                     unitPrice: 1000,
                                                                     date: Date.now)])
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/600.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/))
        .preferredColorScheme(.dark)
        TransactionHistoryView(transactionHistory: [TransactionOrder(quantity: -10,
                                                                     unitPrice: 1000,
                                                                     date: Date.now)])
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/600.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/))
        .preferredColorScheme(.dark)
    }
}
