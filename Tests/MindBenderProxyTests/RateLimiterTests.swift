import XCTest
@testable import MindBenderProxy

final class RateLimiterTests: XCTestCase {
    func testAllowsBurstUpToCapacity() async {
        let limiter = RateLimiter(capacity: 5, refillPerSecond: 0.1)
        for _ in 0..<5 {
            let wait = await limiter.consume(key: "1.2.3.4")
            XCTAssertNil(wait)
        }
        let blocked = await limiter.consume(key: "1.2.3.4")
        XCTAssertNotNil(blocked)
    }

    func testRefillsOverTime() async {
        let limiter = RateLimiter(capacity: 2, refillPerSecond: 1)
        let start = Date()
        XCTAssertNil(await limiter.consume(key: "k", now: start))
        XCTAssertNil(await limiter.consume(key: "k", now: start))
        XCTAssertNotNil(await limiter.consume(key: "k", now: start))
        let later = start.addingTimeInterval(1.0)
        XCTAssertNil(await limiter.consume(key: "k", now: later))
    }

    func testBucketsAreIsolatedPerKey() async {
        let limiter = RateLimiter(capacity: 1, refillPerSecond: 0.1)
        XCTAssertNil(await limiter.consume(key: "a"))
        XCTAssertNil(await limiter.consume(key: "b"))
        XCTAssertNotNil(await limiter.consume(key: "a"))
    }

    func testEvictionRemovesIdleBuckets() async {
        let limiter = RateLimiter(capacity: 1, refillPerSecond: 0.1)
        let t0 = Date()
        _ = await limiter.consume(key: "old", now: t0)
        _ = await limiter.consume(key: "new", now: t0.addingTimeInterval(7200))
        let beforeCount = await limiter.bucketCount()
        XCTAssertEqual(beforeCount, 2)
        await limiter.evictIdle(olderThan: 3600, now: t0.addingTimeInterval(7200))
        let afterCount = await limiter.bucketCount()
        XCTAssertEqual(afterCount, 1)
    }
}
