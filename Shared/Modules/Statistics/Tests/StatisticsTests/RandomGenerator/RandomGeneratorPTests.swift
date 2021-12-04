//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 04/12/2021.
//

import XCTest
@testable import Statistics

final class RandomGeneratorPTests: XCTestCase {
    struct RNG: RandomGeneratorP {
        typealias Number = Double
        
        mutating func next() -> Double {
            1.0
        }
    }
    
    func test_sequence() {
        var rng = RNG()
        let sequence = rng.sequence(of: 10)
        
        XCTAssertEqual(sequence, [Double].init(repeating: 1.0, count: 10))
    }
    
}

final class UniformRandomGeneratorTests: XCTestCase {
    func test_sequence() {
        var rng = UniformRandomGenerator(minX: 5.0, maxX: 10.0)
        let sequence = rng.sequence(of: 1000)
        
        XCTAssertGreaterThanOrEqual(sequence.min()!, 5.0)
        XCTAssertLessThanOrEqual(sequence.max()!, 10.0)
    }
    
    func test_sequence_nil_min_max() {
        var rng = UniformRandomGenerator()
        let sequence = rng.sequence(of: 1000)
        
        XCTAssertGreaterThanOrEqual(sequence.min()!, 0.0)
        XCTAssertLessThanOrEqual(sequence.max()!, 1.0)
    }
}

final class DiscreteRandomGeneratorTests: XCTestCase {
    func test_sequence() {
        let pdf : [Point] = [[1.0, 0.2], [3.0, 0.5], [4.0, 0.3]]
        var rng = DiscreteRandomGenerator(pdf: pdf)
        rng.initialize()
        
        XCTAssertEqual(rng.pdf.count, pdf.count)
        XCTAssertEqual(rng.minX, 1.0)
        XCTAssertEqual(rng.maxX, 4.0)
        XCTAssertNotNil(rng.cdf)
        if let cdf = rng.cdf {
            XCTAssertEqual(cdf.count, 3)
            XCTAssertEqual(cdf[0], 0.2)
            XCTAssertEqual(cdf[1], 0.7)
            XCTAssertEqual(cdf[2], 1.0)
        }
        XCTAssertNotNil(rng.cdfCurve)
        if let cdfCurve = rng.cdfCurve {
            XCTAssertEqual(cdfCurve.count, 3)
            XCTAssertEqual(cdfCurve[0].x, 1)
            XCTAssertEqual(cdfCurve[1].x, 3)
            XCTAssertEqual(cdfCurve[2].x, 4)
            XCTAssertEqual(cdfCurve[0].y, 0.2)
            XCTAssertEqual(cdfCurve[1].y, 0.7)
            XCTAssertEqual(cdfCurve[2].y, 1.0)
        }
        
        let sequence = rng.sequence(of: 1000)
        
        XCTAssertGreaterThanOrEqual(sequence.min()!, 1.0)
        XCTAssertLessThanOrEqual(sequence.max()!, 4.0)
        var nb1 = 0
        var nb3 = 0
        var nb4 = 0
        for sample in sequence {
            XCTAssertTrue(sample == 1.0 || sample == 3.0 || sample == 4.0)
            switch sample {
                case 1:
                    nb1 += 1
                    
                case 3:
                    nb3 += 1
                    
                case 4:
                    nb4 += 1
                    
                default:
                    break
            }
        }
        XCTAssertEqual(nb1.double() / 1000.0, 0.2, accuracy: 0.05)
        XCTAssertEqual(nb3.double() / 1000.0, 0.5, accuracy: 0.05)
        XCTAssertEqual(nb4.double() / 1000.0, 0.3, accuracy: 0.05)
    }
}

final class BetaRandomGeneratorGeneratorTests: XCTestCase {
    func test_sequence() {
        let min = 1.0
        let max = 4.0
        let range = max - min
        var rng = BetaRandomGenerator (minX  : min,
                                       maxX  : max,
                                       alpha : 1.0,
                                       beta  : 1.0)
        rng.initialize()
        
        XCTAssertEqual(rng.minX, 1.0)
        XCTAssertEqual(rng.maxX, 4.0)
        XCTAssertEqual(rng.alpha, 1.0)
        XCTAssertEqual(rng.beta, 1.0)
        XCTAssertNotNil(rng.pdfMax)
        if let pdfMax = rng.pdfMax {
            XCTAssertEqual(pdfMax, 1.0 / range)
        }
        XCTAssertNotNil(rng.cdfCurve)

        let sequence = rng.sequence(of: 1000)

        XCTAssertGreaterThanOrEqual(sequence.min()!, 1.0)
        XCTAssertLessThanOrEqual(sequence.max()!, 4.0)
    }
}
