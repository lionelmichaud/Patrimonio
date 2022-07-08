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
    var name           : String
    var firstDate      : Date
    var lastDate       : Date
    var isProportional : Bool
    var isPeriodic     : Bool = false
    var period         : Int = 1
    var value          : Double
    var valueToDate    : Double
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
                var isPeriodic: Bool
                var period    : Int

                switch expense.timeSpan {
                    case .periodic (_, let thePeriod, _):
                        isPeriodic = true
                        period = thePeriod
                    default:
                        isPeriodic = false
                        period = 1
                }

                table.append(
                    .init(name           : expense.name,
                          firstDate      : date(year: firstYear, month: 1),
                          lastDate       : date(year: lastYear, month: 1),
                          isProportional : expense.proportional,
                          isPeriodic     : isPeriodic,
                          period         : period,
                          value          : expense.value,
                          valueToDate    : expense.value(atEndOf: Int(evalYear)))
                )
            }
        }

        return table
    }

    private var expensePeriodicTable: [ExpenseTimelineChartMark] {
        guard let expenseArray = expenses[category] else {
            return []
        }

        var table = [ExpenseTimelineChartMark]()

        expenseArray.items.forEach { expense in
            if let firstYear = expense.firstYear, let lastYear = expense.lastYear {

                switch expense.timeSpan {
                    case .periodic (_, let thePeriod, _):
                        for year in stride(from: firstYear, through: lastYear, by: thePeriod) {
                            table.append(
                                .init(name           : expense.name,
                                      firstDate      : date(year: year, month: 1),
                                      lastDate       : date(year: year, month: 1),
                                      isProportional : expense.proportional,
                                      isPeriodic     : true,
                                      period         : thePeriod,
                                      value          : expense.value,
                                      valueToDate    : expense.value(atEndOf: Int(year)))
                            )
                        }

                    default: break
                }

            }
        }

        return table
    }

    var body: some View {
        Chart {
            // toutes les dépenses
            ForEach(expenseTable, id: \.name) { element in
                BarMark(
                    xStart: .value("Année début", element.firstDate, unit: .year),
                    xEnd  : .value("Année fin", element.lastDate, unit: .year),
                    y     : .value("Catégorie", element.name)
                )
                // année de début
                .annotation(position: .overlay, alignment: .leading) {
                    Text("\(element.firstDate.year)")
                        .font(.callout)
                }
                // année de fin
                .annotation(position: .overlay, alignment: .trailing) {
                    if element.lastDate.year != element.firstDate.year {
                        Text("\(element.lastDate.year)")
                            .font(.callout)
                    }
                }
                // valeur à la date d'évaluation (curseur)
                .annotation(position: .trailing, alignment: .center) {
                    Text(elementValueLabel(element))
                        .font(.callout)
                }
                .foregroundStyle(
                    Color("Quarterdeck-XL")
                        .opacity(element.isProportional ? 0.6 : 1.0)
                )
            }
            // dépenses périodiques
            ForEach(expensePeriodicTable, id: \.name) { element in
                RuleMark(
                    xStart: .value("Année début", element.firstDate, unit: .year),
                    xEnd  : .value("Année fin", element.lastDate, unit: .year),
                    y     : .value("Catégorie", element.name)
                )
                .lineStyle(StrokeStyle(lineWidth: 3))
                .foregroundStyle(
                    Color("Quarterdeck-XS")
                )
            }
            // ligne verticale
            RuleMark(
                x: .value("Année", evalDate, unit: .year)
            )
            .foregroundStyle(.gray)
            .lineStyle(StrokeStyle(lineWidth: 3))
        }
        .padding(.top)
        .padding(.trailing, 30)
        .overlay(alignment: .topTrailing) {
            CasePicker(pickedCase: $unit, label: "Unité")
                .pickerStyle(.segmented)
                .frame(maxWidth: 100)
                .padding(.trailing)
        }
        .padding([.horizontal, .bottom])
    }

    // MARK: - Methods

    private func elementValueLabel(_ element: ExpenseTimelineChartMark) -> String {
        let propString = element.isProportional ? "(x)" : ""
        if unit == .keuro {
            return element.valueToDate.k€String + propString
        } else {
            return element.valueToDate.€String + propString
        }
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
