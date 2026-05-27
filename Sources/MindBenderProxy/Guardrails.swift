import Foundation

/// Server-side guardrails for kid-safe usage.
///
/// Three checks:
///   1. `containsBlockedWords` — refuses prompts containing profanity / slurs
///      (with simple leetspeak + repeat-collapse normalization).
///   2. `sanitizeReply` — strips dangerous / external-media tags from LLM output
///      (img, iframe, script, video, audio, embed, object, source, track, picture).
///   3. The system prompt itself (see `Sources/Shared/SystemPrompt.swift`).
public enum Guardrails {

    // MARK: - Profanity

    /// Lowercase word-boundary-matched. Severe words only; word boundaries keep
    /// false positives down ("assignment" is fine, "ass" alone is not — but we
    /// don't even include "ass" because it false-positives too often).
    static let blockedWords: Set<String> = [
        "fuck", "fucking", "fucked", "fucker", "motherfucker", "mf",
        "shit", "shitty", "shitting", "bullshit",
        "bitch", "bitches",
        "cunt",
        "pussy",
        "dick", "dicks",
        "cock", "cocks",
        "asshole", "asshat",
        "bastard",
        "piss", "pissed",
        "whore",
        "slut",
        "nigger", "nigga",
        "faggot", "fag",
        "retard", "retarded",
        "kys",
        "porn", "pornhub",
        "sex", "sexy", "nude", "nudes", "naked",
        "kill yourself", "suicide"
    ]

    private static let wordRegex: NSRegularExpression? = {
        let escaped = blockedWords.map { NSRegularExpression.escapedPattern(for: $0) }
        let pattern = "\\b(" + escaped.joined(separator: "|") + ")\\b"
        return try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }()

    public static func containsBlockedWords(_ text: String) -> Bool {
        let normalized = normalize(text)
        guard let regex = wordRegex else { return false }
        let range = NSRange(location: 0, length: (normalized as NSString).length)
        return regex.firstMatch(in: normalized, options: [], range: range) != nil
    }

    /// Lowercase, swap common leet substitutions, collapse 3+ repeats to 1.
    static func normalize(_ text: String) -> String {
        var s = text.lowercased()
        let subs: [(String, String)] = [
            ("0", "o"), ("1", "i"), ("3", "e"), ("4", "a"),
            ("5", "s"), ("7", "t"), ("@", "a"), ("$", "s")
        ]
        for (from, to) in subs {
            s = s.replacingOccurrences(of: from, with: to)
        }
        if let regex = try? NSRegularExpression(pattern: "([a-z])\\1{2,}", options: []) {
            let ns = s as NSString
            s = regex.stringByReplacingMatches(
                in: s,
                options: [],
                range: NSRange(location: 0, length: ns.length),
                withTemplate: "$1"
            )
        }
        return s
    }

    // MARK: - HTML sanitation

    /// Tags the LLM is never allowed to emit. Stops external media,
    /// iframes (could embed adult sites), and any JS execution.
    static let forbiddenTags = [
        "img", "iframe", "video", "audio", "embed",
        "object", "source", "track", "picture", "script"
    ]

    public static func sanitizeReply(_ reply: String) -> String {
        var result = reply
        for tag in forbiddenTags {
            let open = "<\\s*\(tag)\\b[^>]*/?>"
            let close = "<\\s*/\\s*\(tag)\\s*>"
            result = removeMatches(in: result, pattern: open)
            result = removeMatches(in: result, pattern: close)
        }
        return result
    }

    private static func removeMatches(in input: String, pattern: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return input }
        let ns = input as NSString
        return regex.stringByReplacingMatches(
            in: input,
            options: [],
            range: NSRange(location: 0, length: ns.length),
            withTemplate: ""
        )
    }
}
