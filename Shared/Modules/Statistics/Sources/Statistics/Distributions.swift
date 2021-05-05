//
//  Distributions.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

public struct BetaDistribution: Distribution {
    public typealias Number = Double
    
    public static var cdfCurveSamplesNumber : Int = 1000

    // MARK: - Properties
    
    public var minX     : Double?
    public var maxX     : Double?
    public var pdfMax   : Double?
    public var cdfCurve : Curve?

    let alpha : Double
    let beta  : Double

    // MARK: - Methods
    
    public func pdf(_ x: Double) -> Double {
        var xl = x
        if let minX = minX, let maxX = maxX {
            precondition(x >= minX, "BetaDistribution: X < minX")
            precondition(x <= maxX + 0.0001, "BetaDistribution: X > maxX")
            xl = (x - minX) / (maxX - minX)
            return pow((1 - xl), beta - 1.0) * pow(xl, alpha - 1.0) / Statistics.beta(a: alpha, b: beta) / (maxX - minX)
        } else {
            precondition(x >= 0.0, "BetaDistribution: X < 0")
            precondition(x <= 1.0, "BetaDistribution: X > 1")
            return pow((1 - xl), beta - 1.0) * pow(xl, alpha - 1.0) / Statistics.beta(a: alpha, b: beta)
        }
    }
}
