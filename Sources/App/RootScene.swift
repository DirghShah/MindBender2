import SwiftUI

public struct RootScene: Scene {
    @StateObject private var viewModel = PlaygroundViewModel()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 800)
        #endif
    }
}
