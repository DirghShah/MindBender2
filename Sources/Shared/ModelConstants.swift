import Foundation

public enum GroqConfig {
    public static let endpoint = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
    public static let model = "llama-3.3-70b-versatile"
    public static let temperature: Double = 0.4
    public static let maxTokens: Int = 2048
}
