import SwiftUI

public struct PreviewPane: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel

    public init() {}

    public var body: some View {
        WebView(html: viewModel.extractedHTML)
    }
}
