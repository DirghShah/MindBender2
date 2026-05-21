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

        let content = try await GroqClient.send(messages: chatReq.messages, on: req)
        return ChatResponse(content: content)
    }
}
