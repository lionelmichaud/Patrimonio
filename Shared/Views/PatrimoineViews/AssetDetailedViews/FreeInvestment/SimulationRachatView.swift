//
//  SimulationRachatView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 13/04/2022.
//

import SwiftUI
import AssetsModel
import HelpersView

struct SimulationRachatView: View {
    var item: FreeInvestement
    @State private var montantRetraitNet: Double = 0
    @State private var withdrawal = (brutAmount       : 0.0,
                                     brutAmountSplit: (investment: 0.0, interest: 0.0),
                                     revenue          : 0.0,
                                     interests        : 0.0,
                                     netInterests     : 0.0,
                                     taxableInterests : 0.0,
                                     socialTaxes      : 0.0)

    var body: some View {
        Form {
            AmountEditView(label    : "Montant du rachat net",
                           amount   : $montantRetraitNet,
                           validity : .within(range : 0.0 ... item.value(atEndOf : Date.now.year)))
            .onChange(of: montantRetraitNet) {
                withdrawal = item.withdrawal(netAmount: $0,
                                             maxPermitedValue: .infinity)
            }
            AmountView(label: "Montant du rachat brut à réaliser",
                       amount: withdrawal.brutAmount,
                       weight: .bold)
            Group {
                AmountView(label: "Part d'investissement",
                           amount: withdrawal.brutAmountSplit.investment)
                AmountView(label: "Part d'intérêts bruts de charges sociales",
                           amount: withdrawal.brutAmountSplit.interest)
                AmountView(label: "Part d'intérêts nets de charges sociales",
                           amount: withdrawal.netInterests)
                .padding(.leading)
                AmountView(label: "Part imposable à l'IRPP des intérêts nets de charges sociales",
                           amount: withdrawal.taxableInterests)
                .padding(.leading)
            }
            .padding(.leading)
        }
        .navigationTitle("Simulation de rachat")
    }
}

//struct SimulationRachatView_Previews: PreviewProvider {
//    static var previews: some View {
//        SimulationRachatView()
//    }
//}
