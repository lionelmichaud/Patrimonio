//
//  TimeSpanEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import DateBoundary
import HelpersView

// MARK: - View Model for LifeExpenseTimeSpan

struct TimeSpanViewModel: Equatable {
    
    // MARK: - Properties
    
    var caseIndex : Int
    var period    : Int
    var inYear    : Int
    var from      : DateBoundary?
    var to        : DateBoundary?

    // MARK: - Computed Properties
    
    // construire l'objet de type LifeExpenseTimeSpan correspondant au ViewModel
    var timeSpan: TimeSpan {
        switch caseIndex {
            case TimeSpan.permanent.id:
                return .permanent
                
            case TimeSpan.periodic(from: DateBoundary.empty, period: 0, to: DateBoundary.empty).id:
                return .periodic(from   : self.from ?? DateBoundary(fixedYear : CalendarCst.thisYear),
                                 period : self.period,
                                 to     : self.to ?? DateBoundary(fixedYear : CalendarCst.thisYear + 1))
                
            case TimeSpan.starting(from: DateBoundary.empty).id:
                return .starting(from: self.from ?? DateBoundary(fixedYear : CalendarCst.thisYear))
                
            case TimeSpan.ending(to: DateBoundary.empty).id:
                return .ending(to: self.to ?? DateBoundary(fixedYear : CalendarCst.thisYear + 1))
                
            case TimeSpan.spanning(from: DateBoundary.empty, to: DateBoundary.empty).id:
                return .spanning(from : self.from ?? DateBoundary(fixedYear : CalendarCst.thisYear),
                                 to   : self.to  ?? DateBoundary(fixedYear : CalendarCst.thisYear + 1))
                
            case TimeSpan.exceptional(inYear:0).id:
                return .exceptional(inYear: self.inYear)
                
            default:
                fatalError("LifeExpenseTimeSpan : Case out of bound")
        }
    }
    
    // MARK: - Initializers of ViewModel from Model
    
    internal init(from timeSpan: TimeSpan) {
        self.caseIndex = timeSpan.id
        switch timeSpan {
            case .exceptional(let inYear):
                self.inYear = inYear
            default:
                self.inYear = CalendarCst.thisYear
        }
        switch timeSpan {
            case .periodic(_, let period, _):
                self.period = period
            default:
                self.period = 1
        }
        switch timeSpan {
            case .starting (let from),
                    .periodic(let from, _, _),
                    .spanning(let from, _):
                self.from = from
            default:
                self.from = nil
        }
        switch timeSpan {
            case .ending (let to),
                    .periodic(_, _, let to),
                    .spanning(_, let to):
                self.to = to
            default:
                self.to = nil
        }
    }
    
    internal init() {
        self = TimeSpanViewModel(from: .permanent)
    }
}

// MARK: - View

struct TimeSpanEditView: View {
    
    // MARK: - Properties
    
    @Binding var timeSpan : TimeSpan
    private var timeSpanVM : Binding<TimeSpanViewModel> {
        Binding(
            get: {
                TimeSpanViewModel(from: self.timeSpan)
            },
            set: {
                self.timeSpan = $0.timeSpan
            }
        )
    }

    // MARK: - Computed Properties
    
    var body: some View {
        Group {
            Section {
                // choisir le type de TimeFrame pour la dépense
                CaseWithAssociatedValuePicker<TimeSpan>(caseIndex: timeSpanVM.caseIndex, label: "")
                    .pickerStyle(.segmented)
            } header: {
                Text("PLAGE DE TEMPS")
            }
            // en fonction du type choisi
            switch timeSpanVM.wrappedValue.caseIndex {
                case TimeSpan.permanent.id :
                    // TimeSpan = .ending
                    EmptyView()

                case TimeSpan.ending(to: DateBoundary.empty).id :
                    // TimeSpan = .ending
                    BoundaryEditView2(label    : "Fin (exclue)",
                                      boundary : timeSpanVM.to)

                case TimeSpan.starting(from: DateBoundary.empty).id :
                    // TimeSpan = .starting
                    BoundaryEditView2(label    : "Début",
                                      boundary : timeSpanVM.from)

                case TimeSpan.spanning(from: DateBoundary.empty,
                                       to: DateBoundary.empty).id :
                    // TimeSpan = .spanning
                    BoundaryEditView2(label    : "Début",
                                      boundary : timeSpanVM.from)
                    BoundaryEditView2(label    : "Fin (exclue)",
                                      boundary : timeSpanVM.to)

                case TimeSpan.periodic(from: DateBoundary.empty,
                                       period: 1,
                                       to: DateBoundary.empty).id :
                    // TimeSpan = .periodic
                    BoundaryEditView2(label    : "Début",
                                      boundary : timeSpanVM.from)
                    BoundaryEditView2(label     : "Fin (exclue)",
                                      boundary : timeSpanVM.to)
                    Section {
                        Stepper(value: timeSpanVM.period, in: 0...100, step: 1, label: {
                            HStack {
                                Text("Période")
                                Spacer()
                                Text("\(timeSpanVM.wrappedValue.period) ans").foregroundColor(.secondary)
                            }
                        })
                    } header: {
                        Text("Période")
                    }

                case TimeSpan.exceptional(inYear: 0).id :
                    // TimeSpan = .exceptional
                    IntegerEditView(label    : "Durant l'année",
                                    integer  : timeSpanVM.inYear,
                                    validity : .poz)

                default:
                    Text("Cas inconnu: ceci est un bug").foregroundColor(.red)
            }
        }
    }
}

struct TimeSpanEditView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            TimeSpanEditView(
                timeSpan: .constant(TimeSpan.periodic(from: DateBoundary(fixedYear: 2021),
                                                      period: 5, to: DateBoundary(fixedYear: 2031)))
            )
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding([.bottom, .top])
            .previewDisplayName("TimeSpanEditView")
        }
    }
}
