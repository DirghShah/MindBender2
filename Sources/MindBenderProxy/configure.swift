import Vapor

public func configure(_ app: Application) async throws {
    // Permissive CORS for classroom dev (kids' iPads hitting teacher's laptop).
    let cors = CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    ))
    app.middleware.use(cors, at: .beginning)

    // Bind from env (defaults match .env.example).
    app.http.server.configuration.hostname = Environment.get("BIND_HOST") ?? "0.0.0.0"
    if let portString = Environment.get("BIND_PORT"), let port = Int(portString) {
        app.http.server.configuration.port = port
    } else {
        app.http.server.configuration.port = 8080
    }

    // Verify the Groq key is present at boot — fail fast otherwise.
    guard let key = Environment.get("GROQ_API_KEY"), !key.isEmpty else {
        app.logger.critical("GROQ_API_KEY is not set. Copy .env.example to .env and fill it in.")
        throw Abort(.internalServerError, reason: "GROQ_API_KEY missing")
    }
    app.logger.info("Groq key loaded (length=\(key.count))")

    // Shared rate limiter across requests.
    let limiter = RateLimiter()
    app.storage[RateLimiterKey.self] = limiter
    app.middleware.use(RateLimitMiddleware(limiter: limiter))
    app.lifecycle.use(RateLimiterEviction(limiter: limiter))

    try routes(app)
}
