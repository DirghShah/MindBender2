import Vapor
import Shared

func routes(_ app: Application) throws {
    app.get("health") { _ in
        ["status": "ok"]
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

        // 1. Block prompts containing profanity / unsafe terms.
        for message in chatReq.messages where message.role == .user {
            if Guardrails.containsBlockedWords(message.content) {
                req.logger.notice("blocked prompt from \(req.remoteAddress?.ipAddress ?? "unknown")")
                throw Abort(
                    .unprocessableEntity,
                    reason: "Let's keep things friendly. Try a different prompt."
                )
            }
        }

        // 2. Send to Groq (server-trusted system prompt is prepended inside GroqClient).
        let raw = try await GroqClient.send(messages: chatReq.messages, on: req)

        // 3. Strip forbidden tags from the LLM output before returning to the app.
        let safe = Guardrails.sanitizeReply(raw)

        return ChatResponse(content: safe)
    }
}
