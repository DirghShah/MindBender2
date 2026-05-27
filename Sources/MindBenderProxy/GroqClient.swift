import Vapor
import Shared

struct GroqRequest: Content {
    struct Message: Content {
        let role: String
        let content: String
    }
    let model: String
    let messages: [Message]
    let temperature: Double
    let max_tokens: Int
}

struct GroqResponse: Content {
    struct Choice: Content {
        struct Message: Content { let role: String; let content: String }
        let message: Message
    }
    struct Usage: Content {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
    let choices: [Choice]
    let usage: Usage?
}

struct GroqError: Content {
    struct ErrorBody: Content { let message: String? }
    let error: ErrorBody?
}

struct GroqResult {
    let content: String
    let totalTokens: Int
}

enum GroqClient {
    static func send(messages userMessages: [ChatMessage], on req: Request) async throws -> GroqResult {
        guard let key = Environment.get("GROQ_API_KEY"), !key.isEmpty else {
            throw Abort(.internalServerError, reason: "GROQ_API_KEY missing")
        }

        var payload: [GroqRequest.Message] = [
            .init(role: "system", content: SystemPrompt.text)
        ]
        for m in userMessages where m.role != .system {
            payload.append(.init(role: m.role.rawValue, content: m.content))
        }

        let body = GroqRequest(
            model: GroqConfig.model,
            messages: payload,
            temperature: GroqConfig.temperature,
            max_tokens: GroqConfig.maxTokens
        )

        let response = try await req.client.post(URI(string: GroqConfig.endpoint.absoluteString)) { out in
            out.headers.add(name: "Authorization", value: "Bearer \(key)")
            out.headers.contentType = .json
            try out.content.encode(body)
        }

        guard response.status == .ok else {
            let detail = (try? response.content.decode(GroqError.self).error?.message) ?? response.body.map(String.init(buffer:)) ?? "no body"
            req.logger.error("Groq upstream error \(response.status): \(detail)")
            throw Abort(.badGateway, reason: "LLM error: \(detail)")
        }

        let decoded = try response.content.decode(GroqResponse.self)
        guard let content = decoded.choices.first?.message.content else {
            throw Abort(.badGateway, reason: "LLM returned no choices")
        }
        return GroqResult(content: content, totalTokens: decoded.usage?.total_tokens ?? 0)
    }
}
