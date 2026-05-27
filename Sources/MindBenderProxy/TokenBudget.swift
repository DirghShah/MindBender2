import Foundation
import Vapor

/// Tracks token usage across the whole class for the day. Resets at UTC midnight.
/// In-memory only — restarting the proxy zeroes the counter, which is fine for
/// a one-classroom-session use case but means you shouldn't restart mid-class.
public actor TokenBudget {
    public let dailyLimit: Int
    private var usedToday: Int = 0
    private var dayKey: String = ""

    public init(dailyLimit: Int, now: Date = .init()) {
        self.dailyLimit = dailyLimit
        self.dayKey = Self.dayKey(for: now)
    }

    /// Returns `true` if there is room to send another request to Groq today.
    public func tryReserve(now: Date = .init()) -> Bool {
        rolloverIfNeeded(now: now)
        return usedToday < dailyLimit
    }

    /// Account for tokens actually consumed by a Groq response.
    public func record(tokens: Int, now: Date = .init()) {
        rolloverIfNeeded(now: now)
        usedToday += max(0, tokens)
    }

    public func snapshot(now: Date = .init()) -> UsageResponse {
        rolloverIfNeeded(now: now)
        return UsageResponse(used: usedToday, limit: dailyLimit)
    }

    private func rolloverIfNeeded(now: Date) {
        let key = Self.dayKey(for: now)
        if key != dayKey {
            usedToday = 0
            dayKey = key
        }
    }

    static func dayKey(for date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }
}

public struct TokenBudgetKey: StorageKey {
    public typealias Value = TokenBudget
}
