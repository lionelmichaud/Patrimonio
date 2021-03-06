//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 17/04/2021.
//

import Foundation

// MARK: - Point(x, y)

public struct Point: Codable, ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Double
    
    var x: Double
    var y: Double
    
    public init(arrayLiteral elements: Double...) {
        self.x = elements[0]
        self.y = elements[1]
    }
    
    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}
