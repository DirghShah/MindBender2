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

        // 1. Only check the latest user message — historical messages were already
        //    vetted when they were sent, and re-checking them poisons the chat
        //    forever once a single bad word slips into the transcript.
        if let latest = chatReq.messages.last(where: { $0.role == .user }),
           Guardrails.containsBlockedWords(latest.content) {
            req.logger.notice("blocked prompt from \(req.remoteAddress?.ipAddress ?? "unknown")")
            throw Abort(
                .unprocessableEntity,
                reason: "Let's keep things friendly. Try a different prompt."
            )
        }

        // 2. Defense in depth: scrub any blocked-word user messages from history
        //    before forwarding to Groq, so the LLM never sees toxic context even
        //    if the client app failed to remove them.
        let scrubbedMessages = chatReq.messages.filter { msg in
            msg.role != .user || !Guardrails.containsBlockedWords(msg.content)
        }

        // 3. Send to Groq (server-trusted system prompt is prepended inside GroqClient).
        let raw = try await GroqClient.send(messages: scrubbedMessages, on: req)

        // 4. Strip forbidden tags from the LLM output before returning to the app.
        let safe = Guardrails.sanitizeReply(raw)

        return ChatResponse(content: safe)
    }
}
