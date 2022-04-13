//
//  BuyScpiSheet.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 11/04/2022.
//

import SwiftUI
import AppFoundation
import AssetsModel
import HelpersView

struct BuyScpiSheet: View {
    var buyOrSell: BuySell
    @Transac var scpi: SCPI
    @Environment(\.dismiss) private var dismiss
    @State private var transac = TransactionOrder()

    var toolBar: some View {
        /// Barre de titre
        HStack {
            Button("Annuler") {
                dismiss()
            }.buttonStyle(.bordered)

            Spacer()
            Text(buyOrSell == .buy ? "Acheter des parts" : "Vendre des parts").font(.title).fontWeight(.bold)
            Spacer()

            Button("OK", action: commit)
                .buttonStyle(.bordered)
                .disabled(!formIsValid())
        }
        .padding(.horizontal)
        .padding(.top)
    }

    var body: some View {
        VStack {
            /// Barre de titre
            toolBar

            Text(scpi.name)
                .font(.title3)
                .padding(.top)

            /// Formulaire
            Form {
                DatePicker(selection           : $transac.date,
                           displayedComponents : .date,
                           label               : { Text("Date") })

                AmountEditView(label    : buyOrSell == .buy ? "Prix unitaire d'acquisition" : "Prix unitaire de vente",
                               amount   : $transac.unitPrice,
                               validity : .poz)

                IntegerEditView(label    : "Quantité",
                                integer  : $transac.quantity,
                                validity : buyOrSell == .buy ? .poz : .noz)
            }
        }
    }

    private func formIsValid() -> Bool {
        transac.unitPrice.isPOZ &&
        ((buyOrSell == .buy && transac.quantity.isPOZ) || (buyOrSell == .sell && transac.quantity.isNOZ))
    }

    /// L'utilisateur a cliqué sur OK
    private func commit() {
        // ajouter la transaction à l'historique
        scpi.transactionHistory.append(transac)
        dismiss()
    }

}

struct BuyScpiSheet_Previews: PreviewProvider {
    static var previews: some View {
        BuyScpiSheet(buyOrSell: .buy,
                     scpi: .init(source: SCPI()))
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/600.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/400.0/*@END_MENU_TOKEN@*/))
        .preferredColorScheme(.dark)
        BuyScpiSheet(buyOrSell: .sell,
                     scpi: .init(source: SCPI()))
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/600.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/400.0/*@END_MENU_TOKEN@*/))
        .preferredColorScheme(.dark)
   }
}
