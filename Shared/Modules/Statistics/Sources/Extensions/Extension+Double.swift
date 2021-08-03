//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 17/04/2021.
//

import Foundation

extension Double: RandomizableP {
    public static func randomized(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }
}
