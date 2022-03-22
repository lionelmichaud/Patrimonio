//
//  PropertyWrappers.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

/// Retourne max(value, 0.0)
///
/// Usage:
///
///     @ZeroOrPositive var score = 0
///
@propertyWrapper
public struct ZeroOrPositive<T: Numeric & Comparable> {
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

/// Retourne min(value, 0.0)
///
/// Usage:
///
///     @ZeroOrNegative var score = 0
///
@propertyWrapper
public struct ZeroOrNegative<T: Numeric & Comparable> {
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

/// Clamps a value in a range.
///
/// Usage:
///    ```
///    @Clamped(range: 0.0...100.0) var value: Double
///
///    func setScore2(@Clamped(range: 0...100) to score: Int) {
///        print("Setting score to \(score)")
///    }
///    ```
@propertyWrapper
public struct Clamped<T: Comparable> {
    public let wrappedValue: T

    init(wrappedValue: T, range: ClosedRange<T>) {
        self.wrappedValue = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}
