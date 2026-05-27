import SwiftUI
import Shared

@MainActor
public final class PlaygroundViewModel: ObservableObject {
    @Published public var messages: [ChatMessage] = []
    @Published public var extractedHTML: String = PlaygroundViewModel.emptyHTML
    @Published public var isSending: Bool = false
    @Published public var lastError: String?
    @Published public var proxyBaseURL: URL {
        didSet {
            UserDefaults.standard.set(proxyBaseURL.absoluteString, forKey: Self.proxyKey)
            Task { await client.updateBaseURL(proxyBaseURL) }
        }
    }

    private let client: ProxyClient

    private static let proxyKey = "proxyBaseURL"
    public static let emptyHTML = """
    <!DOCTYPE html><html><head><meta charset="utf-8"><style>
      html,body { height:100%; margin:0; font-family: system-ui, sans-serif; }
      body { display:flex; align-items:center; justify-content:center; color:#888; background:#fafafa; }
    </style></head><body>Your live preview will appear here.</body></html>
    """

    public init() {
        let stored = UserDefaults.standard.string(forKey: Self.proxyKey)
        let url = stored.flatMap(URL.init(string:)) ?? URL(string: "http://localhost:8080")!
        self.proxyBaseURL = url
        self.client = ProxyClient(baseURL: url)
    }

    public func send(_ userText: String) async {
        let trimmed = userText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        lastError = nil
        messages.append(ChatMessage(role: .user, content: trimmed))
        isSending = true
        defer { isSending = false }

        do {
            let reply = try await client.send(messages: messages)
            messages.append(ChatMessage(role: .assistant, content: reply))
            extractedHTML = HTMLExtractor.extract(from: reply)
        } catch {
            // Server rejected the prompt (profanity / unsafe). Drop the offending
            // user message from history so it doesn't get re-sent as context.
            if case ProxyError.refused = error, messages.last?.role == .user {
                messages.removeLast()
            }
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    public func clearChat() {
        messages.removeAll()
        extractedHTML = Self.emptyHTML
        lastError = nil
    }
}
