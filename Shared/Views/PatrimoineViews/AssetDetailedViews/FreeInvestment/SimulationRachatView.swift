//
//  SimulationRachatView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 13/04/2022.
//

import SwiftUI
import AssetsModel
import HelpersView
import ModelEnvironment
import FamilyModel

struct SimulationRachatView: View {
    var item: FreeInvestement
    
    @EnvironmentObject var model  : Model
    @EnvironmentObject var family : Family

    @State
    private var montantRetraitNet: Double = 0

    @State
    private var withdrawal = (brutAmount       : 0.0,
                              brutAmountSplit: (investment: 0.0, interest: 0.0),
                              revenue          : 0.0,
                              interests        : 0.0,
                              netInterests     : 0.0,
                              taxableInterests : 0.0,
                              socialTaxes      : 0.0)
    @State
    private var impot: Double = 0

    var body: some View {
        Form {
            AmountEditView(label    : "Montant souhaité net de charges sociales",
                           amount   : $montantRetraitNet,
                           validity : .within(range : 0.0 ... item.value(atEndOf : Date.now.year)))
            .onChange(of: montantRetraitNet) { newValue in
                computeWithdrawal(montantRetraitNet: newValue)
            }
            AmountView(label: "Montant du rachat à réaliser",
                       amount: withdrawal.brutAmount,
                       weight: .bold)
            Group {
                AmountView(label: "Part d'investissement comprise dans le rachat",
                           amount: withdrawal.brutAmountSplit.investment)
                AmountView(label: "Part de plus value comprise dans le rachat (brute de charges sociales)",
                           amount: withdrawal.brutAmountSplit.interest)
                AmountView(label: "Charges sociales sur la part de plus value",
                           amount: -withdrawal.socialTaxes)
                .padding(.leading)
                AmountView(label: "Part de plus value nette de charges sociales",
                           amount: withdrawal.netInterests)
                .padding(.leading)
                AmountView(label: "Part de plus value imposable",
                           amount: withdrawal.taxableInterests)
                .padding(.leading)
                AmountView(label: "Impôt sur la part de plus value ",
                           amount: -impot)
                .padding(.leading)
            }
            .padding(.leading)
            AmountView(label: "Montant obtenu net de charges sociales",
                       amount: withdrawal.brutAmount - withdrawal.socialTaxes,
                       weight: .bold)
            AmountView(label: "Montant obtenu net de charges sociales et d'impôt",
                       amount: withdrawal.brutAmount - withdrawal.socialTaxes - impot,
                       weight: .bold)
        }
        .navigationTitle("Simulation de rachat")
    }

    private func computeWithdrawal(montantRetraitNet: Double) {
        withdrawal = item.withdrawal(netAmount: montantRetraitNet,
                                     maxPermitedValue: .infinity)
        // impôt sur les plus-values
        switch item.type {
            case .lifeInsurance:
                // taxation au prélèvement libératoire de 7,5% pour les plus values
                // générées par les versements avant le 27/09/2017
                impot =
                FreeInvestement
                    .fiscalModel
                    .lifeInsuranceTaxes
                    .flatTax(plusValueTaxable: withdrawal.taxableInterests,
                                            nbOfAdultAlive: family.nbOfAdultAlive(atEndOf: Date.now.year))
            case .pea:
                // pas d'impôt sur les plus-values au-delà de 8 ans de détention du PEA
                impot = 0.0

            case .other:
                impot =
                FreeInvestement
                    .fiscalModel
                    .financialRevenuTaxes
                    .flatTax(plusValueTaxable: withdrawal.taxableInterests)
        }
    }
}

//struct SimulationRachatView_Previews: PreviewProvider {
//    static var previews: some View {
//        SimulationRachatView()
//    }
//}
