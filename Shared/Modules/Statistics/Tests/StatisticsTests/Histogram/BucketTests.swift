import XCTest
@testable import Statistics

final class BucketTests: XCTestCase {

    func test_creat_bucket_fini() {
        let bucket = Bucket(Xmin: 10.0,
                            Xmax: 90.0)
        XCTAssertEqual(bucket.Xmin, 10.0)
        XCTAssertEqual(bucket.Xmax, 90.0)
        XCTAssertEqual(bucket.Xmed, (10.0 + 90.0) / 2.0)
    }

    func test_creat_bucket_moins_infini_nil_step() {
        let bucket = Bucket(Xmin: -Double.infinity,
                            Xmax: 90.0)
        XCTAssertEqual(bucket.Xmin, -Double.infinity)
        XCTAssertEqual(bucket.Xmax, 90.0)
        XCTAssertEqual(bucket.Xmed, bucket.Xmax)
    }

    func test_creat_bucket_moins_infini_step() {
        let bucket = Bucket(Xmin: -Double.infinity,
                            Xmax: 90.0,
                            borderBucketWidth: 10.0)
        XCTAssertEqual(bucket.Xmin, -Double.infinity)
        XCTAssertEqual(bucket.Xmax, 90.0)
        XCTAssertEqual(bucket.Xmed, bucket.Xmax - 10.0)
    }

    func test_creat_bucket_plus_infini_nil_step() {
        let bucket = Bucket(Xmin: 10.0,
                            Xmax: Double.infinity)
        XCTAssertEqual(bucket.Xmin, 10.0)
        XCTAssertEqual(bucket.Xmax, Double.infinity)
        XCTAssertEqual(bucket.Xmed, bucket.Xmin)
    }

    func test_creat_bucket_plus_infini_step() {
        let bucket = Bucket(Xmin: 10.0,
                            Xmax: Double.infinity,
                            borderBucketWidth: 10.0)
        XCTAssertEqual(bucket.Xmin, 10.0)
        XCTAssertEqual(bucket.Xmax, Double.infinity)
        XCTAssertEqual(bucket.Xmed, bucket.Xmin + 10.0)
    }

    func test_record() {
        var bucket = Bucket(Xmin: 10.0,
                            Xmax: 90.0)
        XCTAssertEqual(bucket.sampleNb, 0)
        for i in 1...100 {
            bucket.record()
            XCTAssertEqual(bucket.sampleNb, i)
        }
        bucket.empty()
        XCTAssertEqual(bucket.sampleNb, 0)
    }

}
