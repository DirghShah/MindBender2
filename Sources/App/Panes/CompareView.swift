import SwiftUI

public struct CompareView: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel
    let onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                pane(title: "Target") {
                    if let data = viewModel.targetImage, let img = Image(platformData: data) {
                        img.resizable().scaledToFit()
                    } else {
                        Text("No target loaded").foregroundStyle(.secondary)
                    }
                }
                Divider()
                pane(title: "Live Preview") {
                    WebView(html: viewModel.extractedHTML)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                    .padding(16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close compare view")
        }
    }

    @ViewBuilder
    private func pane<Content: View>(title: String, @ViewBuilder _ body: () -> Content) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.gray.opacity(0.08))
            body()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
