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
    @Environment(\.dismiss) private var dismiss
    @Transac var scpi: SCPI
    @State private var quantity: Int = 0
    @State private var unitPrice: Double = 0

    var toolBar: some View {
        /// Barre de titre
        HStack {
            Button("Annuler") {
                dismiss()
            }.buttonStyle(.bordered)

            Spacer()
            Text("Acheter des parts").font(.title).fontWeight(.bold)
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
                AmountEditView(label    : "Prix d'acquisition",
                               amount   : $unitPrice,
                               validity : .poz)
                IntegerEditView(label    : "Quantité",
                                integer  : $quantity,
                                validity : .poz)
            }
        }
    }

    private func formIsValid() -> Bool {
        unitPrice.isPOZ && unitPrice.isPOZ
    }

    /// L'utilisateur a cliqué sur OK
    private func commit() {
        // incrémenter le prix total d'acquisition
        scpi.buyingPrice += unitPrice * quantity.double()

        dismiss()
    }

}

struct BuyScpiSheet_Previews: PreviewProvider {
    static var previews: some View {
        BuyScpiSheet(scpi: .init(source: SCPI()))
    }
}
