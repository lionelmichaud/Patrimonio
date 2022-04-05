//
//  Constants.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

public struct CalendarCst {
    public static let nowComponents = Date.calendar.dateComponents([.year, .month, .day], from: Date())
    public static let thisYear      = nowComponents.year!
    //public static let now           = Date()
    public static let forever       = 3000
    public static let endOfYearDate = Date.calendar.nextDate(after: Date(),
                                                             matching: DateComponents(calendar: Date.calendar, month: 12, day: 31),
                                                             matchingPolicy: .nextTime)
    public static let endOfYearComp = Date.calendar.dateComponents([.year, .month, .day], from: endOfYearDate!)
}
