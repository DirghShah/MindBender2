import Foundation

public struct UsageResponse: Codable, Sendable {
    public var used: Int
    public var limit: Int
    public var remaining: Int { max(0, limit - used) }

    public init(used: Int, limit: Int) {
        self.used = used
        self.limit = limit
    }
}
