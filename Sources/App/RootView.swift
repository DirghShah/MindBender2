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
        contentForPlatform
            .sheet(isPresented: $showSettings) {
                SettingsSheet().environmentObject(viewModel)
            }
            .confirmationDialog("Start a new chat?", isPresented: $confirmClear) {
                Button("Clear chat and preview", role: .destructive) { viewModel.clearChat() }
                Button("Cancel", role: .cancel) {}
            }
    }

    @ViewBuilder
    private var contentForPlatform: some View {
        #if os(iOS)
        if sizeClass == .compact {
            compactTabs
        } else {
            splitView
        }
        #else
        splitView
        #endif
    }

    private var compactTabs: some View {
        TabView {
            NavigationStack {
                ChatPane()
                    .navigationTitle("Chat")
                    .toolbar { toolbarItems }
            }
            .tabItem { Label("Chat", systemImage: "text.bubble") }

            NavigationStack {
                PreviewPane()
                    .navigationTitle("Preview")
                    .toolbar { toolbarItems }
            }
            .tabItem { Label("Preview", systemImage: "play.rectangle") }
        }
    }

    private var splitView: some View {
        NavigationSplitView {
            ChatPane()
                .navigationSplitViewColumnWidth(min: 320, ideal: 420)
                .toolbar { toolbarItems }
                .navigationTitle("MindBender")
        } detail: {
            PreviewPane()
                .navigationTitle("Preview")
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { confirmClear = true } label: {
                Image(systemName: "square.and.pencil")
            }
            .help("New chat")
            .accessibilityLabel("New chat")
            .disabled(viewModel.messages.isEmpty)
        }
        ToolbarItem(placement: .primaryAction) {
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
            .help("Settings")
            .accessibilityLabel("Settings")
        }
    }
}
