//
//  StatisticsProtocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Numerics

public struct PointReal<Number: Real> : Codable where Number: Codable {
    public var x: Number
    public var y: Number
}

enum RandomizingMethod {
    case rejectionSampling
    case inverseTransform
}

let randomizingMethod: RandomizingMethod = .inverseTransform

// MARK: - Protocol Distribution statistique entre minX et maxX

/// Protocol Distribution statistique entre minX et maxX
///
/// La distribution est caractérisée par:
///  - Une Fonction de Densité de Probabilité `pdf` sur l'intervalle [`minX`, `maxX`]
///  - Une Fonction de Densité Cumulée de Probabilité `cdf` sur l'intervalle [`minX`, `maxX`]
///
public protocol DistributionP {
    associatedtype Number: Real, Codable
    typealias Curve = [PointReal<Number>]
    
    // MARK: - Type Properties
    
    static var cdfCurveSamplesNumber : Int { get }
    
    // MARK: - Properties
    
    /// valeur minimale de X
    var minX     : Number? { get set }
    /// valeur maximale de X
    var maxX     : Number? { get set }
    /// valeur max de la PDF, calculée et mémorisée au premier appel de initialize()
    var pdfMax   : Number? { get set }
    /// courbe CDF, calculée et mémorisée au premier appel de initialize()
    var cdfCurve : Curve? { get set }
    
    // MARK: - Methods
    
    /// Initialiser les variables qui ne changeront jamais: `pdfMax` et `cdfCurve`
    mutating func initialize() // voir impémentation par défaut
    
    /// Densité de probabilité en un point x
    /// - Parameter x: valeur du domaine de la distribution P(x) [`minX`, `maxX`]
    func pdf(_ x: Number) -> Number
    
    /// Retourne la probabilité P cumulée correspondant à une valeur x du domaine de la distribution P(x)
    /// - Parameter x: valeur du domaine de la distribution P(x) [`minX`, `maxX`]
    /// - Returns: probabilité P cumulée correspondant à une valeur x
    func cdf(x: Number) -> Number // impémentation par défaut
    
    /// Retourne la valeur x du domaine de la distribution P(X) telle que la probabilité cumulée P(x) ≥ p
    /// - Parameter p: probabilité cumulée
    /// - Returns: valeur x du domaine de la distribution P(X)
    func inverseCdf(p: Number) -> Number // impémentation par défaut
}

/// implémentation par défaut
public extension DistributionP {

    mutating func initialize() {
        
        func computedPdfMax() -> Number {
            var maxPdf = -Number.infinity
            let nbSample = 1000
            let step = (maxX - minX) / Number(nbSample - 1)
            func x(_ i: Int) -> Number { minX + Number(i) * step }
            for i in 0..<nbSample {
                let p = pdf(x(i))
                if p > maxPdf {
                    maxPdf = p
                }
            }
            return maxPdf
        }
        
        func computedCdfCurve(length: Int) -> Curve {
            let step = (maxX - minX) / Number(length - 1)
            func x(_ i: Int) -> Number { minX + Number(i) * step }
            var s = Number.zero
            
            var curve = Curve()
            for i in 0..<length-1 {
                curve.append(PointReal(x: x(i), y: s))
                // surface du trapèze élémentaire entre deux points x successifs
                let ds = (x(i+1) - x(i)) * (pdf(x(i)) + pdf(x(i+1))) / 2
                // intégrale sur [minX, x]
                s += ds
            }
            curve.append(PointReal(x: maxX, y: Number(1)))
            return curve
        }
        
        let minX = self.minX ?? Number.zero
        let maxX = self.maxX ?? Number(1)
        
        precondition(minX < maxX, "Distribution.initialize: minX >= maxX")
        
        // initialiser la valeur de pdfMax
        self.pdfMax = computedPdfMax()
        
        // initialiser la courbe de CDF
        self.cdfCurve = computedCdfCurve(length: Self.cdfCurveSamplesNumber)
    }
    
    func cdf(x: Number) -> Number {
        guard let curve = cdfCurve else {
            fatalError("Distribution.cdf: CDF curve not initialized")
        }
        guard let idx = curve.firstIndex(where: { x <= $0.x }) else {
            fatalError("Distribution.cdf: x out of bound")
        }
        if idx > 0 {
            // interpolation
            let k = (x - curve[idx-1].x) / (curve[idx].x - curve[idx-1].x)
            return curve[idx-1].y + k * (curve[idx].y - curve[idx-1].y)
        } else {
            return curve[idx].y
        }
    }
    
    func inverseCdf(p: Number) -> Number {
        guard let cdfCurve = cdfCurve else {
            fatalError("Distribution.inverseCdf: CDF curve not initialized")
        }
        guard let idx = cdfCurve.firstIndex(where: { p <= $0.y }) else {
            fatalError("Distribution.inverseCdf: p out of bound")
        }
        if idx > 0 {
            // interpolation
            let k = (p - cdfCurve[idx-1].y) / (cdfCurve[idx].y - cdfCurve[idx-1].y)
            return cdfCurve[idx-1].x + k * (cdfCurve[idx].x - cdfCurve[idx-1].x)
        } else {
            return cdfCurve[idx].y
        }
    }
    
}

// MARK: - Protocol Générateur Aléatoire

/// Protocol Générateur Aléatoire
public protocol RandomGeneratorP: Equatable {
    associatedtype Number: Real
    
    // MARK: - Methods
    
    mutating func next() -> Number
    mutating func sequence(of length: Int) -> [Number] // impémentation par défaut
}

/// implémentation par défaut
public extension RandomGeneratorP {
    mutating func sequence(of length: Int) -> [Number] {
        precondition(length >= 1, "RandomGenerator.sequence: length < 1")
        var seq = [Number]()
        for _ in 1...length {
            seq.append(next())
        }
        return seq
    }
}

/// implémentation par défaut uniquement pour les RandomGenerator conformes au protocol Distribution
public extension RandomGeneratorP where Self: DistributionP, Number: RandomizableP {
    
    /// Génération aléatoire par la méthode de Rejection sampling ou Inverse Transform
    /// - Returns: valeur aléatoire suivant la fonction de distribution pdf(x)
    ///
    ///  - Note:
    ///  [Reference] (https://en.wikipedia.org/wiki/Rejection_sampling)
    ///
    ///  [Reference] (https://en.wikipedia.org/wiki/Inverse_transform_sampling)
    ///
    mutating func next() -> Number {
        switch randomizingMethod {
            case .rejectionSampling:
                /*
                 Rejection sampling works as follows:
                 1. Sample a point on the x-axis from the proposal distribution.
                 2. Draw a vertical line at this x-position, up to the maximum y-value of the proposal distribution.
                 3. Sample uniformly along this line from 0 to the maximum of the probability density function.
                    If the sampled value is greater than the value of the desired distribution at this vertical line, reject the x-value and return to step 1;
                    else the x-value is a sample from the desired distribution.
                 */
                repeat {
                    /// Step 1. Sample a point on the x-axis from the proposal distribution.
                    let range = (minX ?? .zero) ... (maxX ?? Number(1))
                    let x = Number.randomized(in: range)
                    /// Step 2. Draw a vertical line at this x-position, up to the maximum y-value of the proposal distribution.
                    guard let ymax = pdfMax else {
                        fatalError("RandomGenerator.next(): pdfMax not initialized")
                    }
                    guard ymax.isFinite else {
                        return .zero
                    }
                    /// Step3. Sample uniformly along this line from 0 to the maximum of the probability density function.
                    let y = Number.randomized(in: .zero ... ymax)
                    if y <= pdf(x) {
                        /// Step3. If the sampled value is greater than the value of the desired distribution at this vertical line,
                        ///       reject the x-value and return to step 1; else the x-value is a sample from the desired distribution.
                        return x
                    }
                } while true
                
            case .inverseTransform:
                /*
                 Inverse transformation sampling takes uniform samples of a number
                 u between 0 and 1, interpreted as a probability, and then returns the largest number
                 x from the domain of the distribution P(X) such that (-∞< X < x) ≤ u
                 */
                /// Step 1. Generate a random number u from the standard uniform distribution in the interval [0,1]
                let u = Number.randomized(in: 0...1)
                
                /// Step 2. Find the largest number x from the domain of the distribution P(X) such that (-∞< X < x) ≤ u
                return inverseCdf(p: u)
        }
        
    }
}

// MARK: - Protocol de service générateur aléatoire dans un interval

/// Protocol de service générateur aléatoire dans un interval
public protocol RandomizableP: Comparable {
    static func randomized(in range: ClosedRange<Self>) -> Self
}
