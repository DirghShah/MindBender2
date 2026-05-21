import Vapor
import Foundation

public actor RateLimiter {
    public struct Bucket {
        var tokens: Double
        var lastRefill: Date
    }

    public let capacity: Double
    public let refillPerSecond: Double
    private var buckets: [String: Bucket] = [:]

    public init(capacity: Double = 10, refillPerSecond: Double = 0.2) {
        self.capacity = capacity
        self.refillPerSecond = refillPerSecond
    }

    /// Returns `nil` if allowed; otherwise returns the seconds the caller should wait.
    public func consume(key: String, now: Date = .init()) -> Double? {
        var bucket = buckets[key] ?? Bucket(tokens: capacity, lastRefill: now)
        let elapsed = now.timeIntervalSince(bucket.lastRefill)
        if elapsed > 0 {
            bucket.tokens = min(capacity, bucket.tokens + elapsed * refillPerSecond)
            bucket.lastRefill = now
        }
        if bucket.tokens >= 1 {
            bucket.tokens -= 1
            buckets[key] = bucket
            return nil
        } else {
            let needed = 1 - bucket.tokens
            buckets[key] = bucket
            return needed / refillPerSecond
        }
    }

    public func evictIdle(olderThan seconds: TimeInterval, now: Date = .init()) {
        buckets = buckets.filter { now.timeIntervalSince($0.value.lastRefill) < seconds }
    }

    public func bucketCount() -> Int { buckets.count }
}

// MARK: - Vapor wiring

public struct RateLimiterKey: StorageKey {
    public typealias Value = RateLimiter
}

public struct RateLimitMiddleware: AsyncMiddleware {
    let limiter: RateLimiter

    public init(limiter: RateLimiter) {
        self.limiter = limiter
    }

    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Only rate-limit the chat endpoint; leave health/static alone.
        guard request.url.path.hasPrefix("/chat") else {
            return try await next.respond(to: request)
        }
        let key = request.headers.first(name: "X-Forwarded-For")?
            .split(separator: ",").first.map(String.init)?
            .trimmingCharacters(in: .whitespaces)
            ?? request.remoteAddress?.ipAddress
            ?? "unknown"
        if let waitSeconds = await limiter.consume(key: key) {
            let retry = max(1, Int(waitSeconds.rounded(.up)))
            let response = Response(status: .tooManyRequests)
            response.headers.replaceOrAdd(name: "Retry-After", value: "\(retry)")
            response.headers.contentType = .json
            response.body = .init(string: #"{"error":"Too many tries, wait a few seconds."}"#)
            return response
        }
        return try await next.respond(to: request)
    }
}

public struct RateLimiterEviction: LifecycleHandler {
    let limiter: RateLimiter
    public init(limiter: RateLimiter) { self.limiter = limiter }

    public func didBootAsync(_ application: Application) async throws {
        let limiter = self.limiter
        let logger = application.logger
        Task.detached {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
                await limiter.evictIdle(olderThan: 3600)
                logger.debug("rate limiter eviction sweep complete")
            }
        }
    }
}
