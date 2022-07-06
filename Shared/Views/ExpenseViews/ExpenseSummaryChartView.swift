//
//  ExpenseSummaryChartView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/07/2022.
//

import SwiftUI
import LifeExpense
import Charts

enum CurrencyUnit {
    case euro
    case keuro
}

@available(iOS 16.0, *)
struct ExpenseSummaryChartView: View {
    let evalDate : Double

    @EnvironmentObject var expenses : LifeExpensesDic

    @State
    private var unit: CurrencyUnit = .euro

    var body: some View {
        Chart {
            ForEach(expenses.namedTotalValueTable(atEndOf: Int(evalDate)), id: \.name) { element in
                BarMark(
                    x: .value("Montant", element.value),
                    y: .value("Catégorie", element.name)
                )
                .annotation(position: .overlay, alignment: .trailing) {
                    Text(unit == .keuro ? element.value.k€String : element.value.€String)
                }
            }
        }
        .foregroundStyle(Color("tableRowBaseColor"))
        .overlay(alignment: .topTrailing) {
            Picker("Unité", selection: $unit.animation()) {
                Text("€").tag(CurrencyUnit.euro)
                Text("k€").tag(CurrencyUnit.keuro)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 100)
            .padding()
        }
        .padding([.horizontal, .bottom])
    }
}

@available(iOS 16.0, *)
struct ExpenseSummaryChartView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ExpenseSummaryChartView(evalDate: 2023)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.uiState)
    }
}
