import Foundation

public struct Uniform<Base: RandomNumberGenerator> {
    public var base: Base
    
    init(base: Base) {
        self.base = base
    }
    
    /// Returns a value from uniform distribution.
    /// - Parameter range: Range of uniform distribution.
    public mutating func next<T: BinaryFloatingPoint>(in range: Range<T>) -> T
        where T.RawSignificand : FixedWidthInteger {
            return T.random(in: range, using: &base)
    }
    
    /// Returns a value from uniform distribution.
    /// - Parameter range: Range of uniform distribution
    public mutating func next<T: BinaryFloatingPoint>(in range: ClosedRange<T>) -> T
        where T.RawSignificand : FixedWidthInteger {
            return T.random(in: range, using: &base)
    }
}

public struct Normal<Base: RandomNumberGenerator> {
    public var base: Base
    
    init(base: Base) {
        self.base = base
    }
    
    /// Sample from (0, high)
    mutating func sample<T: SinLog>(high: T) -> T
        where T.RawSignificand : FixedWidthInteger {
            var r: T = 0
            
            repeat {
                r = .random(in: 0..<high, using: &base)
            } while r == 0
            
            return r
    }
    
    mutating func next_generic<T: SinLog>(mu: T, sigma: T) -> T
        where T.RawSignificand : FixedWidthInteger {
            precondition(sigma >= 0, "Invalid argument: `sigma` must not be less than 0.")
            
            // Box-Muller's method
            let x: T = sample(high: 1)
            let y: T = sample(high: .pi*2)
            
            return sigma * sqrt(-2*T.log(x)) * T.sin(y) + mu
    }
    
    /// Returns a value from N(mu, sigma^2) distribution.
    /// - Precondition:
    ///   - `sigma` >= 0
    public mutating func next(mu: Float, sigma: Float) -> Float {
        return next_generic(mu: mu, sigma: sigma)
    }
    
    /// Returns a value from N(mu, sigma^2) distribution.
    /// - Precondition:
    ///   - `sigma` >= 0
    public mutating func next(mu: Double, sigma: Double) -> Double {
        return next_generic(mu: mu, sigma: sigma)
    }
}

extension RandomNumberGenerator {
    public var uniform: Uniform<Self> {
        get {
            return Uniform(base: self)
        }
        set {
            self = newValue.base
        }
    }
    
    public var normal: Normal<Self> {
        get {
            return Normal(base: self)
        }
        set {
            self = newValue.base
        }
    }
}
