//
//  DateRangeEditView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI
import AppFoundation

// MARK: - Saisie d'un intervalle de Dates

public struct DateRangeEditView: View {
    public let fromLabel         : String
    @Binding
    public var fromDate : Date
    public let toLabel           : String
    @Binding
    public var toDate   : Date
    public let `in`              : ClosedRange<Date>?
    
    public var body: some View {
        VStack {
            if `in` != nil {
                // contraintes sur la plage de dates
                DatePicker(selection           : $fromDate,
                           in                  : `in`!.lowerBound...`in`!.upperBound,
                           displayedComponents : .date,
                           label               : { Text(fromLabel) })
                
                DatePicker(selection           : $toDate,
                           in                  : max(fromDate, `in`!.lowerBound)...Date.distantFuture,
                           displayedComponents : .date,
                           label               : { Text(toLabel) })
            } else {
                DatePicker(selection           : $fromDate,
                           displayedComponents : .date,
                           label               : { Text(fromLabel) })
                
                DatePicker(selection           : $toDate,
                           displayedComponents : .date,
                           label               : { Text(toLabel) })
            }
        }
    }
}

// MARK: - PreViews

struct DateRangeEditView_Previews: PreviewProvider {
    static var previews: some View {
        DateRangeEditView(fromLabel: "Label1",
                          fromDate: .constant(CalendarCst.now),
                          toLabel: "Label2",
                          toDate: .constant(CalendarCst.now),
                          in: 1.months.ago!...3.years.fromNow!)
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding([.bottom, .top])
            .previewDisplayName("DateRangeEditView")
    }
}

// MARK: - Library Views

struct DateRangeEditView_Library: LibraryContentProvider { // swiftlint:disable:this type_name
    @LibraryContentBuilder var views: [LibraryItem] {
        LibraryItem(DateRangeEditView(fromLabel: "Label1",
                                      fromDate: .constant(CalendarCst.now),
                                      toLabel: "Label2",
                                      toDate: .constant(CalendarCst.now),
                                      in: 1.months.ago!...3.years.fromNow!),
                    title: "Date Range Edit View",
                    category: .control,
                    matchingSignature: "daterange")
    }
}
