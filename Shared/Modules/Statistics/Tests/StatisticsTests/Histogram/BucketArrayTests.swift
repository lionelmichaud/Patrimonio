import XCTest
@testable import Statistics

final class BucketArrayTests: XCTestCase {

    func test_array() {
        var bucketsArray = BucketsArray()
        for idx in 0...9 {
            bucketsArray.append(Bucket(Xmin: Double(idx) * 10.0,
                                       Xmax: Double(idx+1) * 10.0))
        }
        for s in 0...999 {
            let sample = Double(s) / 10.0
            bucketsArray.record(sample)
        }

        for idx in 0...9 {
            XCTAssertEqual(bucketsArray[idx].sampleNb, 100)
        }

        let emptyBucketArray = bucketsArray.emptyCopy()
        for idx in 0...9 {
            XCTAssertEqual(emptyBucketArray[idx].sampleNb, 0)
        }
    }
}
