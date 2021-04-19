//
//  FormaterDate.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

public var longDateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

public var mediumDateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

public var shortDateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

public var dayMonthLongFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "ddMMMM" // format Janv., Fevr., Mars
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

public var dayMonthMediumFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MMM" // format Janv., Fevr., Mars
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

public var dayMonthShortFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM" // format Janv., Fevr., Mars
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

public var monthLongFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM" // format January, February, March
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

public var monthMediumFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM" // format Janv., Fevr., Mars
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()

public var monthShortFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM" // format 01, 02, 03
    formatter.locale = Locale(identifier: "fr_FR") // French Locale (fr_FR)
    return formatter
}()
