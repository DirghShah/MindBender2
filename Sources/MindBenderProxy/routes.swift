import Vapor
import Shared

func routes(_ app: Application) throws {
    app.get("health") { _ in
        ["status": "ok"]
    }

    app.get("usage") { req async -> UsageResponse in
        guard let budget = req.application.storage[TokenBudgetKey.self] else {
            return UsageResponse(used: 0, limit: 0)
        }
        return await budget.snapshot()
    }

    app.post("chat") { req async throws -> ChatResponse in
        let chatReq = try req.content.decode(ChatRequest.self)
        guard !chatReq.messages.isEmpty else {
            throw Abort(.badRequest, reason: "messages cannot be empty")
        }
        guard chatReq.messages.count <= 40 else {
            throw Abort(.badRequest, reason: "too many messages in history")
        }
        let totalChars = chatReq.messages.reduce(0) { $0 + $1.content.count }
        guard totalChars <= 20_000 else {
            throw Abort(.badRequest, reason: "message history too long")
        }

        // 1. Profanity check on the latest user message only.
        if let latest = chatReq.messages.last(where: { $0.role == .user }),
           Guardrails.containsBlockedWords(latest.content) {
            req.logger.notice("blocked prompt from \(req.remoteAddress?.ipAddress ?? "unknown")")
            throw Abort(
                .unprocessableEntity,
                reason: "Let's keep things friendly. Try a different prompt."
            )
        }

        // 2. Daily token budget gate.
        if let budget = req.application.storage[TokenBudgetKey.self] {
            let snapshot = await budget.snapshot()
            guard await budget.tryReserve() else {
                throw Abort(
                    .serviceUnavailable,
                    reason: "We've used today's token budget (\(snapshot.limit.formatted())). Please try again tomorrow."
                )
            }
        }

        // 3. Scrub any historical blocked-word messages defensively.
        let scrubbedMessages = chatReq.messages.filter { msg in
            msg.role != .user || !Guardrails.containsBlockedWords(msg.content)
        }

        // 4. Send to Groq.
        let result = try await GroqClient.send(messages: scrubbedMessages, on: req)

        // 5. Record actual token usage from Groq's response.
        if let budget = req.application.storage[TokenBudgetKey.self] {
            await budget.record(tokens: result.totalTokens)
        }

        // 6. Strip forbidden tags before returning to the app.
        let safe = Guardrails.sanitizeReply(result.content)

        return ChatResponse(content: safe)
    }
}
