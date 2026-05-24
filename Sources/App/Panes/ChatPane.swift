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
            inputBar
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if viewModel.messages.isEmpty && !viewModel.isSending {
                        emptyState
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                    } else {
                        ForEach(viewModel.messages) { msg in
                            MessageRow(message: msg)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(IDETheme.placeholder)
            Text("Describe what you want to build.")
                .font(.system(size: 13))
                .foregroundStyle(IDETheme.placeholder)
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(IDETheme.divider).frame(height: 1)
            HStack(alignment: .bottom, spacing: 8) {
                TextField("", text: $draft, axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(IDETheme.bubbleText)
                    .focused($inputFocused)
                    .onSubmit(send)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(IDETheme.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(IDETheme.inputBorder, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if draft.isEmpty {
                            Text("Describe what you want to build…")
                                .font(.system(size: 13))
                                .foregroundStyle(IDETheme.placeholder)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }

                Button(action: send) {
                    Image(systemName: viewModel.isSending ? "ellipsis" : "arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(canSend ? Color.accentColor : Color.gray.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(10)
        }
    }

    private var canSend: Bool {
        !viewModel.isSending && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        let text = draft
        draft = ""
        Task { await viewModel.send(text) }
    }
}

private struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(roleLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(IDETheme.roleLabel)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(displayContent)
                .font(.system(size: 13))
                .foregroundStyle(IDETheme.bubbleText)
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(bubbleColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        case .assistant: return "MindBender"
        case .system: return "System"
        }
    }

    private var bubbleColor: Color {
        switch message.role {
        case .user: return IDETheme.userBubble
        case .assistant: return IDETheme.assistantBubble
        case .system: return Color.yellow.opacity(0.12)
        }
    }
}

private struct ThinkingRow: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Thinking…")
                .font(.system(size: 12))
                .foregroundStyle(IDETheme.placeholder)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
    }
}

private struct ErrorRow: View {
    let message: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(IDETheme.bubbleText)
        }
        .padding(10)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
