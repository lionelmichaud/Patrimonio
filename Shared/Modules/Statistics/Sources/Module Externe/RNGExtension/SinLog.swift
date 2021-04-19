import Foundation

protocol SinLog: BinaryFloatingPoint {
    static func sin(_ x: Self) -> Self
    static func log(_ x: Self) -> Self
}

extension Float: SinLog {
    static func sin(_ x: Float) -> Float {
        return Foundation.sin(x)
    }
    static func log(_ x: Float) -> Float {
        return Foundation.log(x)
    }
}

extension Double: SinLog {
    static func sin(_ x: Double) -> Double {
        return Foundation.sin(x)
    }
    static func log(_ x: Double) -> Double {
        return Foundation.log(x)
    }
}
