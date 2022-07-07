//
//  ExpenseDetailedChartView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 06/07/2022.
//

import SwiftUI
import Charts
import AppFoundation
import LifeExpense
import HelpersView

struct ExpenseTimelineChartMark {
    var name         : String
    var firstDate    : Date
    var lastDate     : Date
    var proportional : Bool
    var value        : Double
    var valueToDate  : Double
}

@available(iOS 16.0, *)
struct ExpenseTimelineChartView: View {
    let evalYear : Double
    let category : LifeExpenseCategory
    
    @EnvironmentObject var expenses : LifeExpensesDic

    @State
    private var unit: CurrencyUnit = .keuro

    // MARK: - Computed Properties

    private var evalDate: Date {
        date(year: Int(evalYear), month: 1)
    }

    private var expenseTable: [ExpenseTimelineChartMark] {
        guard let expenseArray = expenses[category] else {
            return []
        }

        var table = [ExpenseTimelineChartMark]()

        expenseArray.items.forEach { expense in
            if let firstYear = expense.firstYear, let lastYear = expense.lastYear {
                table.append(
                    .init(name         : expense.name,
                          firstDate    : date(year: firstYear, month: 1),
                          lastDate     : date(year: lastYear, month: 1),
                          proportional : expense.proportional,
                          value        : expense.value,
                          valueToDate  : expense.value(atEndOf: Int(evalYear)))
                )
            }
        }

        return table
    }

    var body: some View {
        Chart {
            ForEach(expenseTable, id: \.name) { element in
                BarMark(
                    xStart: .value("Année début", element.firstDate, unit: .year),
                    xEnd: .value("Année fin", element.lastDate, unit: .year),
                    y: .value("Catégorie", element.name)
                )
                .annotation(position: .overlay, alignment: .leading) {
                    Text("\(element.firstDate.year)")
                        .font(.callout)
                }
                .annotation(position: .overlay, alignment: .trailing) {
                    if element.lastDate.year != element.firstDate.year {
                        Text("\(element.lastDate.year)")
                            .font(.callout)
                    }
                }
                .annotation(position: .trailing, alignment: .center) {
                    Text(unit == .keuro ? element.valueToDate.k€String : element.valueToDate.€String)
                        .font(.callout)
                }
                .foregroundStyle(Color("tableRowBaseColor"))
            }
            RuleMark(
                x: .value("Année", evalDate, unit: .year)
            )
            .foregroundStyle(.gray)
            .lineStyle(StrokeStyle(lineWidth: 3))
        }
        .padding(.trailing, 30)
        .overlay(alignment: .topTrailing) {
            CasePicker(pickedCase: $unit, label: "Unité")
                .pickerStyle(.segmented)
                .frame(maxWidth: 100)
                .padding(.trailing)
        }
        .padding()
    }
}

@available(iOS 16.0, *)
struct ExpenseDetailedChartView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseTimelineChartView(
            evalYear : 2023,
            category : .educationFamille
        )
    }
}
