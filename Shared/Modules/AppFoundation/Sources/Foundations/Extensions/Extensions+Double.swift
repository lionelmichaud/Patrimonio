//
//  Extensions+Double.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

public extension Double {
    var roundedString: String {
        String(format: "%.f", self.rounded())
    }

    /**
     :returns: *true* if self is positive number
     */
    var isPositive: Bool {
        return ( self > 0 )
    }

    /**
     :returns: *true* if self is negative number
     */
    var isNegative: Bool {
        return ( self < 0 )
    }

    /**
     :returns: *true* if self is zero
     */
    var isZero: Bool {
        return ( self == 0 )
    }

    /**
     :returns: *true* if self is positive or zero
     */
    var isPOZ: Bool {
        return ( self.isPositive || self.isZero )
    }

    /**
     :returns: *true* if self is negative or zero
     */
    var isNOZ: Bool {
        return ( self.isNegative || self.isZero )
    }
}

public extension Double {
    var €String: String {
        formatted(.currency(code: "eur").precision(.fractionLength(0)))
    }

    func €String(digit: Int = 0) -> String {
        guard digit >= 0 else {
            return "??"
        }
        formatted(.currency(code: "eur").precision(.fractionLength(digit)))
    }

    var k€String: String {
        valueKilo€Formatter.string(from: self as NSNumber) ?? ""
    }

    var percentStringRounded: String {
        formatted(.percent.precision(.fractionLength(0)))
    }

    func percentNormString(digit: Int = 0) -> String {
        guard digit >= 0 else {
            return "??"
        }
        return self.formatted(.percent.precision(.fractionLength(digit)))
    }

    func percentString(digit: Int = 0) -> String {
        (self/100.0).percentNormString(digit: digit)
    }
}
