import Vapor
import Shared

// Conformances live in the Vapor-only module so Shared stays Vapor-free.
extension ChatRequest: Content {}
extension ChatResponse: Content {}
extension ChatMessage: Content {}
