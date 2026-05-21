import Foundation

public enum HTMLExtractor {
    /// Extract a usable HTML document from an LLM reply.
    ///
    /// Strategy (in order):
    ///   1. ```html ... ``` fenced block.
    ///   2. ```        ... ``` ungrouped fenced block.
    ///   3. First substring spanning <!DOCTYPE or <html ... </html>.
    ///   4. Wrap the trimmed reply in a minimal <html><body>...</body></html> shell.
    public static func extract(from reply: String) -> String {
        if let fenced = matchFirst(in: reply, pattern: "```\\s*html\\s*\\n([\\s\\S]*?)```", caseInsensitive: true) {
            return fenced.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let fenced = matchFirst(in: reply, pattern: "```[a-zA-Z]*\\s*\\n([\\s\\S]*?)```", caseInsensitive: true) {
            let trimmed = fenced.trimmingCharacters(in: .whitespacesAndNewlines)
            if looksLikeHTML(trimmed) { return trimmed }
        }
        let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        if looksLikeHTML(trimmed) { return trimmed }
        let escaped = htmlEscape(trimmed.isEmpty ? "(no reply)" : trimmed)
        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8"><style>
          body { font-family: system-ui, sans-serif; padding: 24px; color: #333; }
          pre  { white-space: pre-wrap; background: #f5f5f5; padding: 12px; border-radius: 6px; }
        </style></head>
        <body>
          <p>The assistant did not return a full HTML document. Raw reply below:</p>
          <pre>\(escaped)</pre>
        </body></html>
        """
    }

    private static func looksLikeHTML(_ s: String) -> Bool {
        let lower = s.lowercased()
        return lower.contains("<!doctype html") || lower.contains("<html")
    }

    private static func htmlEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    private static func matchFirst(in input: String, pattern: String, caseInsensitive: Bool) -> String? {
        var options: NSRegularExpression.Options = []
        if caseInsensitive { options.insert(.caseInsensitive) }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let ns = input as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: input, options: [], range: range), match.numberOfRanges >= 2 else {
            return nil
        }
        let captured = match.range(at: 1)
        guard captured.location != NSNotFound else { return nil }
        return ns.substring(with: captured)
    }
}
