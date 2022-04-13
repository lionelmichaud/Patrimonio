//
//  DateRangeEditView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI

// MARK: - Affichage d'un intervalle de Dates

public struct DateRangeView: View {
    public let fromLabel : String
    public var fromDate  : Date
    public let toLabel   : String
    public var toDate    : Date

    public var body: some View {
        HStack {
            Text(fromLabel)
            Spacer()
            Text("\(fromDate.stringLongDate)")
            Spacer()
            Text(toLabel)
            Spacer()
            Text("\(toDate.stringLongDate)")
        }
    }

    public init(fromLabel : String,
                fromDate  : Date,
                toLabel   : String,
                toDate    : Date) {
        self.fromLabel = fromLabel
        self.fromDate  = fromDate
        self.toLabel   = toLabel
        self.toDate    = toDate
    }
}

// MARK: - Saisie d'un intervalle de Dates

public struct DateRangeEditView: View {
    public let fromLabel : String
    @Binding
    public var fromDate  : Date
    public let toLabel   : String
    @Binding
    public var toDate    : Date
    public let `in`      : ClosedRange<Date>?

    public var body: some View {
        VStack {
            if `in` != nil {
                // contraintes sur la plage de dates
                DatePicker(selection           : $fromDate,
                           in                  : `in`!.lowerBound...`in`!.upperBound,
                           displayedComponents : .date,
                           label               : { Text(fromLabel) })
                .if(fromDate > toDate) {
                    $0.foregroundColor(.red)
                }

                DatePicker(selection           : $toDate,
                           in                  : max(fromDate, `in`!.lowerBound)...Date.distantFuture,
                           displayedComponents : .date,
                           label               : { Text(toLabel) })
                .if(fromDate > toDate) {
                    $0.foregroundColor(.red)
                }
            } else {
                DatePicker(selection           : $fromDate,
                           displayedComponents : .date,
                           label               : { Text(fromLabel) })
                .if(fromDate > toDate) {
                    $0.foregroundColor(.red)
                }

                DatePicker(selection           : $toDate,
                           displayedComponents : .date,
                           label               : { Text(toLabel) })
                .if(fromDate > toDate) {
                    $0.foregroundColor(.red)
                }
            }
        }
    }

    public init(fromLabel : String,
                fromDate  : Binding<Date>,
                toLabel   : String,
                toDate    : Binding<Date>,
                in        : ClosedRange<Date>?) {
        self.fromLabel = fromLabel
        self._fromDate = fromDate
        self.toLabel   = toLabel
        self._toDate   = toDate
        self.in        = `in`
    }
}

// MARK: - PreViews

struct DateRangeEditView_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeEditView(fromLabel: "Label1",
                          fromDate: .constant(Date.now),
                          toLabel: "Label2",
                          toDate: .constant(Date.now),
                          in: 1.months.ago!...3.years.fromNow!)
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding([.bottom, .top])
            .previewDisplayName("DateRangeEditView")
    }
}

// MARK: - Library Views

struct DateRangeEditView_Library: LibraryContentProvider { // swiftlint:disable:this type_name
    @LibraryContentBuilder var views: [LibraryItem] {
        LibraryItem(DateRangeEditView(fromLabel : "Label1",
                                      fromDate  : .constant(Date.now),
                                      toLabel   : "Label2",
                                      toDate    : .constant(Date.now),
                                      in        : 1.months.ago!...3.years.fromNow!),
                    title: "Date Range Edit View",
                    category: .control,
                    matchingSignature: "daterange")
    }
}
