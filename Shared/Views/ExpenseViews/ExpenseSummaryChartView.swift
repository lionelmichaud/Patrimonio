//
//  ExpenseSummaryChartView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/07/2022.
//

import SwiftUI
import AppFoundation
import NamedValue
import LifeExpense
import Charts
import HelpersView

enum CurrencyUnit: PickableEnumP {
    case euro
    case keuro

    var pickerString: String {
        switch self {
            case .euro : return "€"
            case .keuro : return "k€"
        }
    }
}

@available(iOS 16.0, *)
struct ExpenseSummaryChartView: View {
    let evalDate      : Double
    let allCategories : Bool
    let category      : LifeExpenseCategory

    @EnvironmentObject private var expenses : LifeExpensesDic

    @State
    private var unit: CurrencyUnit = .euro

    private var expenseTable: NamedValueArray {
        if allCategories {
            return expenses.namedTotalValueTable(atEndOf: Int(evalDate))
        } else {
            let namedValueDico = expenses.namedValueTable(atEndOf: Int(evalDate))
            return namedValueDico[category] ?? NamedValueArray()
        }
    }

    var body: some View {
        Chart {
            ForEach(expenseTable, id: \.name) { element in
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
        .padding()
        .overlay(alignment: .topTrailing) {
            CasePicker(pickedCase: $unit.animation(), label: "Unité")
                .pickerStyle(.segmented)
                .frame(maxWidth: 100)
                .padding(.trailing)
        }
    }
}

@available(iOS 16.0, *)
struct ExpenseSummaryChartView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ExpenseSummaryChartView(evalDate      : 2023,
                                       allCategories : true,
                                       category      : .educationFamille)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.uiState)
    }
}
