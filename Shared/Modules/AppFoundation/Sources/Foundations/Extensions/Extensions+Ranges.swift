//
//  Extensions+Ranges.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

public extension ClosedRange {
    func hasIntersection(with otherRange: ClosedRange) -> Bool where Bound: Strideable, Bound.Stride: SignedInteger {
        return self.clamped(to: otherRange).count > 1 ||
            otherRange.clamped(to: self) .count > 1
    }
}
