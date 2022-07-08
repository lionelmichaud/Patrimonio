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
struct ExpenseValueChartView: View {
    let evalYear      : Double
    let allCategories : Bool
    let category      : LifeExpenseCategory

    @EnvironmentObject private var expenses : LifeExpensesDic

    @State
    private var unit: CurrencyUnit = .keuro

    private var expenseTable: NamedValueArray {
        if allCategories {
            return expenses.namedTotalValueTable(atEndOf: Int(evalYear))
        } else {
            let namedValueDico = expenses.namedValueTable(atEndOf: Int(evalYear))
            return namedValueDico[category] ?? NamedValueArray()
        }
    }

    private var totalExpense: Double? {
        if allCategories {
            return expenses.value(atEndOf: Int(evalYear))

        } else if let selectedExpenses = expenses.perCategory[category] {
            return selectedExpenses.value(atEndOf: Int(evalYear))

        } else {
            return nil
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
                    if element.value != 0 {
                        Text(unit == .keuro ? element.value.k€String : element.value.€String)
                            .font(.callout)
                    }
                }
                .annotation(position: .trailing, alignment: .leading) {
                    if let totalExpense, (element.value != 0) {
                        Text((element.value / totalExpense).percentStringRounded)
                            .font(.callout)
                    }
                }
           }
        }
        .foregroundStyle(Color("Quarterdeck-XL"))
        .padding(.top)
        .overlay(alignment: .topTrailing) {
            CasePicker(pickedCase: $unit, label: "Unité")
                .pickerStyle(.segmented)
                .frame(maxWidth: 100)
                .padding(.trailing)
        }
        .padding([.horizontal, .bottom])
    }
}

@available(iOS 16.0, *)
struct ExpenseSummaryChartView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ExpenseValueChartView(evalYear      : 2023,
                                       allCategories : true,
                                       category      : .educationFamille)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.uiState)
    }
}
