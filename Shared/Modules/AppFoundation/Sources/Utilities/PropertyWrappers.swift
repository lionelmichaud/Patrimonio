//
//  PropertyWrappers.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

/// Usage:
///     @NonNegative var score = 0
@propertyWrapper public struct NonNegative<T: Numeric & Comparable> {
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
