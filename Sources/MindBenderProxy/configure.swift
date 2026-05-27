import Vapor

public func configure(_ app: Application) async throws {
    let cors = CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    ))
    app.middleware.use(cors, at: .beginning)

    app.http.server.configuration.hostname = Environment.get("BIND_HOST") ?? "0.0.0.0"
    if let portString = Environment.get("BIND_PORT"), let port = Int(portString) {
        app.http.server.configuration.port = port
    } else {
        app.http.server.configuration.port = 8080
    }

    guard let key = Environment.get("GROQ_API_KEY"), !key.isEmpty else {
        app.logger.critical("GROQ_API_KEY is not set. Copy .env.example to .env and fill it in.")
        throw Abort(.internalServerError, reason: "GROQ_API_KEY missing")
    }
    app.logger.info("Groq key loaded (length=\(key.count))")

    // Rate limit (per IP). Defaults: 60 burst, 60/minute sustained.
    let capacity = Double(Environment.get("RATE_LIMIT_CAPACITY") ?? "") ?? 60
    let refillPerSec = Double(Environment.get("RATE_LIMIT_REFILL_PER_SEC") ?? "") ?? 1.0
    let limiter = RateLimiter(capacity: capacity, refillPerSecond: refillPerSec)
    app.storage[RateLimiterKey.self] = limiter
    app.middleware.use(RateLimitMiddleware(limiter: limiter))
    app.lifecycle.use(RateLimiterEviction(limiter: limiter))
    app.logger.info("rate limit: capacity=\(Int(capacity)) refill=\(refillPerSec)/sec")

    // Daily token budget shared across all clients.
    let dailyTokenLimit = Int(Environment.get("DAILY_TOKEN_BUDGET") ?? "") ?? 100_000
    let budget = TokenBudget(dailyLimit: dailyTokenLimit)
    app.storage[TokenBudgetKey.self] = budget
    app.logger.info("daily token budget: \(dailyTokenLimit)")

    try routes(app)
}
