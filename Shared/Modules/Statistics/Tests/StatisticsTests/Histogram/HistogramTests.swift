import XCTest
@testable import Statistics

final class HistogramTests: XCTestCase {

    typealias Test = HistogramTests

    static var histogram: Histogram!

    override func setUpWithError() throws {
        Test.histogram = Histogram(name: "histogramme")
    }

    func fill() {
        for s in 0...999 {
            let sample = Double(s) / 10.0
            Test.histogram.record(sample)
        }
    }

    func test_name() {
        XCTAssertEqual(Test.histogram.name, "histogramme")
    }

    func test_record() {
        XCTAssertNil(Test.histogram.lastRecordedValue)
        XCTAssertNil(Test.histogram.min)
        XCTAssertNil(Test.histogram.max)
        XCTAssertNil(Test.histogram.average)
        XCTAssertNil(Test.histogram.median)

        fill()

        XCTAssertEqual(Test.histogram.lastRecordedValue, 99.9)
        XCTAssertFalse(Test.histogram.isInitialized)
        XCTAssertEqual(Test.histogram.min, 0.0 / 10.0)
        XCTAssertEqual(Test.histogram.max, 999.0 / 10.0)
        XCTAssertEqual(Test.histogram.average, (0.0 + 999.0) / 20.0)
        XCTAssertEqual(Test.histogram.median, (499.0/10.0 + 500.0/10.0) / 2.0)
    }

    func test_sort_with_closedEnds_and_default_values() {
        let nbBucket = 10
        fill()
        Test.histogram.sort(distributionType: .continuous,
                            openEnds: false,
                            bucketNb: nbBucket)
        XCTAssertEqual(Test.histogram.Xmin, 0.0 / 10.0)
        XCTAssertEqual(Test.histogram.Xmax, 999.0 / 10.0)
        XCTAssertTrue(Test.histogram.isInitialized)
        XCTAssertEqual(Test.histogram.xValues.count, nbBucket)
        XCTAssertEqual(Test.histogram.counts.count, nbBucket)
        XCTAssertEqual(Test.histogram.xCounts.count, nbBucket)
        XCTAssertEqual(Test.histogram.cumulatedCounts.count, nbBucket)
        XCTAssertEqual(Test.histogram.xCumulatedCounts.count, nbBucket)
        XCTAssertEqual(Test.histogram.PDF.count, nbBucket)
        XCTAssertEqual(Test.histogram.xPDF.count, nbBucket)
        XCTAssertEqual(Test.histogram.CDF.count, nbBucket)
        XCTAssertEqual(Test.histogram.xCDF.count, nbBucket)

        let step: Double = (999.0/10.0 - 0.0/10.0) / nbBucket.double()
        let normalizer: Double = 1000.0 * step

        for idx in 0..<nbBucket {
            let center = Test.histogram.Xmin + step/2.0 + step * idx.double()
            let count  = Test.histogram.counts[idx]
            XCTAssertEqual(Test.histogram.xValues[idx], center, accuracy: 0.0000001)
            XCTAssertEqual(Test.histogram[idx], 100)
            XCTAssertEqual(count, 100)
            XCTAssertEqual(Test.histogram.xCounts[idx].x, center, accuracy: 0.0000001)
            XCTAssertEqual(Test.histogram.xCounts[idx].n, count)
            XCTAssertEqual(Test.histogram.cumulatedCounts[idx], 100 * (idx+1))
            XCTAssertEqual(Test.histogram.xCumulatedCounts[idx].x, center, accuracy: 0.0000001)
            XCTAssertEqual(Test.histogram.xCumulatedCounts[idx].n, 100 * (idx+1))
            XCTAssertEqual(Test.histogram.PDF[idx], Double(count) / normalizer)
            XCTAssertEqual(Test.histogram.xPDF[idx].x, center, accuracy: 0.0000001)
            XCTAssertEqual(Test.histogram.xPDF[idx].p, Double(count) / normalizer)
            XCTAssertEqual(Test.histogram.CDF[idx], (100 * (idx+1)).double() / 1000.0)
            XCTAssertEqual(Test.histogram.xCDF[idx].x, center, accuracy: 0.0000001)
            XCTAssertEqual(Test.histogram.xCDF[idx].p, (100 * (idx+1)).double() / 1000.0)
        }

        XCTAssertEqual(Test.histogram.PDF.sum() * step, 1.0, accuracy: 0.00000001)
        XCTAssertEqual(Test.histogram.CDF.last!, 1.0 , accuracy: 0.00000001)
    }
    
    func test_probability() {
        let nbBucket = 10
        fill()
        Test.histogram.sort(distributionType: .continuous,
                            openEnds: false,
                            bucketNb: nbBucket)
        XCTAssertEqual(Test.histogram.probability(for: -0.1), 1)
        XCTAssertEqual(Test.histogram.probability(for: 0.0), 1)
        XCTAssertEqual(Test.histogram.probability(for: 0.001), 999.0/1000.0)
        
        XCTAssertEqual(Test.histogram.probability(for: 50.0), 500.0/1000.0)

        XCTAssertEqual(Test.histogram.probability(for: 99.85), 1.0/1000.0)
        XCTAssertEqual(Test.histogram.probability(for: 99.9), 1.0/1000.0)
        XCTAssertEqual(Test.histogram.probability(for: 99.91), 0)
        XCTAssertEqual(Test.histogram.probability(for: 100.0), 0)

    }
    
    func test_percentile() {
        let nbBucket = 10
        fill()
        Test.histogram.sort(distributionType: .continuous,
                            openEnds: false,
                            bucketNb: nbBucket)
        XCTAssertEqual(Test.histogram.percentile(for: 1.0), 99.9)
        XCTAssertEqual(Test.histogram.percentile(for: 0.5), 49.9)
        XCTAssertEqual(Test.histogram.percentile(for: 0.745), 74.4)
        XCTAssertEqual(Test.histogram.percentile(for: 0.75), 74.9)
        XCTAssertEqual(Test.histogram.percentile(for: 0.0), 0.0)
    }
    
    func test_reset() {
        let nbBucket = 10
        fill()
        Test.histogram.sort(distributionType: .continuous,
                            openEnds: false,
                            bucketNb: nbBucket)
        XCTAssertTrue(Test.histogram.isInitialized)
        Test.histogram.reset()
        XCTAssertFalse(Test.histogram.isInitialized)
        XCTAssertEqual(Test.histogram.Xmin, 0.0)
        XCTAssertEqual(Test.histogram.Xmax, 0.0)
    }
}
