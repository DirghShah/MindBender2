import SwiftUI

public struct RootView: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel
    @State private var showCompare = false
    @State private var showSettings = false

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    public init() {}

    public var body: some View {
        contentForPlatform
            .sheet(isPresented: $showSettings) {
                SettingsSheet().environmentObject(viewModel)
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showCompare) {
                CompareView(onClose: { showCompare = false })
                    .environmentObject(viewModel)
            }
            #else
            .sheet(isPresented: $showCompare) {
                CompareView(onClose: { showCompare = false })
                    .environmentObject(viewModel)
                    .frame(minWidth: 900, minHeight: 600)
            }
            #endif
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
                TargetPane(showSettings: $showSettings, showCompare: $showCompare)
                    .navigationTitle("Target")
            }
            .tabItem { Label("Target", systemImage: "photo") }

            NavigationStack {
                ChatPane()
                    .navigationTitle("Chat")
            }
            .tabItem { Label("Chat", systemImage: "text.bubble") }

            NavigationStack {
                PreviewPane()
                    .navigationTitle("Preview")
            }
            .tabItem { Label("Preview", systemImage: "play.rectangle") }
        }
    }

    private var splitView: some View {
        NavigationSplitView {
            TargetPane(showSettings: $showSettings, showCompare: $showCompare)
                .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 360)
        } content: {
            ChatPane()
                .navigationSplitViewColumnWidth(min: 320, ideal: 420)
        } detail: {
            PreviewPane()
        }
    }
}
