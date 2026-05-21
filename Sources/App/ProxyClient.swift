import Foundation
import Shared

public enum ProxyError: LocalizedError {
    case rateLimited(retryAfter: Int)
    case badResponse(status: Int, body: String)
    case transport(String)
    case decoding(String)

    public var errorDescription: String? {
        switch self {
        case .rateLimited(let s): return "Too many tries — wait \(s)s and try again."
        case .badResponse(let code, let body): return "Server error \(code): \(body)"
        case .transport(let m): return "Network error: \(m)"
        case .decoding(let m): return "Could not read server reply: \(m)"
        }
    }
}

public actor ProxyClient {
    private let session: URLSession
    private var baseURL: URL

    public init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    public func updateBaseURL(_ url: URL) {
        self.baseURL = url
    }

    public func send(messages: [ChatMessage]) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        let payload = ChatRequest(messages: messages)
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            throw ProxyError.decoding(error.localizedDescription)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ProxyError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ProxyError.transport("Non-HTTP response")
        }
        if http.statusCode == 429 {
            let retry = Int(http.value(forHTTPHeaderField: "Retry-After") ?? "") ?? 5
            throw ProxyError.rateLimited(retryAfter: retry)
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<binary>"
            throw ProxyError.badResponse(status: http.statusCode, body: body)
        }

        do {
            let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
            return decoded.content
        } catch {
            throw ProxyError.decoding(error.localizedDescription)
        }
    }
}
