//
//  PropertyWrappers.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

/// Usage:
///     @ZeroOrPositive var score = 0
@propertyWrapper public struct ZeroOrPositive<T: Numeric & Comparable> {
    var value: T
    
    public var wrappedValue: T {
        get { value }
        
        set {
            if newValue < 0 {
                value = 0
            } else {
                value = newValue
            }
        }
    }
    
    public init(wrappedValue: T) {
        if wrappedValue < 0 {
            self.value = 0
        } else {
            self.value = wrappedValue
        }
    }
}

/// Usage:
///     @ZeroOrNegative var score = 0
@propertyWrapper public struct ZeroOrNegative<T: Numeric & Comparable> {
    var value: T

    public var wrappedValue: T {
        get { value }

        set {
            if newValue > 0 {
                value = 0
            } else {
                value = newValue
            }
        }
    }

    public init(wrappedValue: T) {
        if wrappedValue > 0 {
            self.value = 0
        } else {
            self.value = wrappedValue
        }
    }
}
