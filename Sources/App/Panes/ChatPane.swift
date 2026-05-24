import SwiftUI
import Shared

public struct ChatPane: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            messageList
            Divider()
            inputBar
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 0) }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(viewModel.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    if viewModel.isSending {
                        ThinkingRow()
                    }
                    if let err = viewModel.lastError {
                        ErrorRow(message: err)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try a prompt like:")
                .font(.headline)
            ForEach([
                "Make a big blue button in the middle of the page that says Hello.",
                "Three red boxes in a row with rounded corners.",
                "A simple login form with a username and password field."
            ], id: \.self) { example in
                Button { draft = example } label: {
                    Text("• \(example)")
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(8)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Describe what you want to build…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: viewModel.isSending ? "ellipsis" : "paperplane.fill")
                    .font(.title3)
                    .padding(8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSending || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(8)
    }

    private func send() {
        let text = draft
        draft = ""
        Task { await viewModel.send(text) }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user { Spacer(minLength: 32) }
            VStack(alignment: .leading, spacing: 4) {
                Text(roleLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(displayContent)
                    .textSelection(.enabled)
                    .padding(10)
                    .background(bubbleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            if message.role == .assistant { Spacer(minLength: 32) }
        }
    }

    private var displayContent: String {
        switch message.role {
        case .assistant: return HTMLExtractor.stripFences(from: message.content)
        case .user, .system: return message.content
        }
    }

    private var roleLabel: String {
        switch message.role {
        case .user: return "You"
        case .assistant: return "Assistant"
        case .system: return "System"
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .user: return Color.accentColor.opacity(0.18)
        case .assistant: return Color.gray.opacity(0.12)
        case .system: return Color.yellow.opacity(0.15)
        }
    }
}

private struct ThinkingRow: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Thinking…").foregroundStyle(.secondary)
        }
        .padding(.leading, 8)
    }
}

private struct ErrorRow: View {
    let message: String
    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .padding(8)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
