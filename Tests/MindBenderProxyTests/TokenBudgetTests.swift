import XCTest
@testable import MindBenderProxy

final class TokenBudgetTests: XCTestCase {

    func testReserveSucceedsUntilLimitReached() async {
        let budget = TokenBudget(dailyLimit: 100)
        let canReserve1 = await budget.tryReserve()
        XCTAssertTrue(canReserve1)
        await budget.record(tokens: 99)
        let canReserve2 = await budget.tryReserve()
        XCTAssertTrue(canReserve2)
        await budget.record(tokens: 1)
        let canReserve3 = await budget.tryReserve()
        XCTAssertFalse(canReserve3)
    }

    func testSnapshotReflectsUsage() async {
        let budget = TokenBudget(dailyLimit: 500)
        await budget.record(tokens: 123)
        let snap = await budget.snapshot()
        XCTAssertEqual(snap.used, 123)
        XCTAssertEqual(snap.limit, 500)
        XCTAssertEqual(snap.remaining, 377)
    }

    func testNegativeRecordIsClamped() async {
        let budget = TokenBudget(dailyLimit: 100)
        await budget.record(tokens: -50)
        let snap = await budget.snapshot()
        XCTAssertEqual(snap.used, 0)
    }

    func testRolloverOnNewDay() async {
        let day1 = ISO8601DateFormatter().date(from: "2026-05-26T10:00:00Z")!
        let day2 = ISO8601DateFormatter().date(from: "2026-05-27T10:00:00Z")!
        let budget = TokenBudget(dailyLimit: 100, now: day1)
        await budget.record(tokens: 80, now: day1)
        let snap1 = await budget.snapshot(now: day1)
        XCTAssertEqual(snap1.used, 80)
        let snap2 = await budget.snapshot(now: day2)
        XCTAssertEqual(snap2.used, 0)
    }
}
