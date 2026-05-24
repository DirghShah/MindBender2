import SwiftUI

public struct RootView: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel
    @State private var showSettings = false
    @State private var confirmClear = false

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    public init() {}

    public var body: some View {
        Group {
            #if os(iOS)
            if sizeClass == .compact {
                compactTabs
            } else {
                ideLayout
            }
            #else
            ideLayout
            #endif
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsSheet().environmentObject(viewModel)
        }
        .confirmationDialog("Start a new chat?", isPresented: $confirmClear) {
            Button("Clear chat and preview", role: .destructive) { viewModel.clearChat() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Wide (Mac, iPad landscape) — IDE-style

    private var ideLayout: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                previewColumn
                Divider().background(IDETheme.divider)
                chatColumn
                    .frame(width: 380)
            }
            statusBar
        }
        .background(IDETheme.appBackground.ignoresSafeArea())
    }

    private var previewColumn: some View {
        VStack(spacing: 0) {
            paneHeader(
                icon: "play.rectangle",
                title: "Preview",
                trailing: { EmptyView() }
            )
            PreviewPane()
                .background(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var chatColumn: some View {
        VStack(spacing: 0) {
            paneHeader(
                icon: "sparkles",
                title: "MindBender",
                trailing: { headerButtons }
            )
            ChatPane()
        }
        .background(IDETheme.panelBackground)
    }

    @ViewBuilder
    private var headerButtons: some View {
        Button {
            confirmClear = true
        } label: {
            Image(systemName: "square.and.pencil")
        }
        .help("New chat")
        .disabled(viewModel.messages.isEmpty)

        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape")
        }
        .help("Settings")
    }

    @ViewBuilder
    private func paneHeader<Trailing: View>(
        icon: String,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(IDETheme.headerText)
            Spacer()
            HStack(spacing: 4) {
                trailing()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(IDETheme.iconTint)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(IDETheme.headerBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(IDETheme.divider).frame(height: 1)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.lastError == nil ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(statusText)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(IDETheme.statusText)
            Spacer()
            Text(viewModel.proxyBaseURL.host ?? viewModel.proxyBaseURL.absoluteString)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(IDETheme.statusText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(IDETheme.statusBackground)
        .overlay(alignment: .top) {
            Rectangle().fill(IDETheme.divider).frame(height: 1)
        }
    }

    private var statusText: String {
        if viewModel.isSending { return "Thinking…" }
        if let err = viewModel.lastError { return err }
        return "Ready"
    }

    // MARK: - Compact (iPhone)

    private var compactTabs: some View {
        TabView {
            NavigationStack {
                ChatPane()
                    .navigationTitle("MindBender")
                    .toolbar { toolbarItems }
            }
            .tabItem { Label("Chat", systemImage: "sparkles") }

            NavigationStack {
                PreviewPane()
                    .navigationTitle("Preview")
                    .toolbar { toolbarItems }
            }
            .tabItem { Label("Preview", systemImage: "play.rectangle") }
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { confirmClear = true } label: {
                Image(systemName: "square.and.pencil")
            }
            .disabled(viewModel.messages.isEmpty)
        }
        ToolbarItem(placement: .primaryAction) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
        }
    }
}

enum IDETheme {
    static let appBackground = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let panelBackground = Color(red: 0.15, green: 0.15, blue: 0.17)
    static let headerBackground = Color(red: 0.17, green: 0.17, blue: 0.19)
    static let statusBackground = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let divider = Color.white.opacity(0.08)
    static let headerText = Color.white.opacity(0.92)
    static let statusText = Color.white.opacity(0.55)
    static let iconTint = Color.white.opacity(0.75)
    static let userBubble = Color.accentColor.opacity(0.22)
    static let assistantBubble = Color.white.opacity(0.06)
    static let bubbleText = Color.white.opacity(0.92)
    static let inputBackground = Color.white.opacity(0.05)
    static let inputBorder = Color.white.opacity(0.12)
    static let placeholder = Color.white.opacity(0.35)
    static let roleLabel = Color.white.opacity(0.45)
}
