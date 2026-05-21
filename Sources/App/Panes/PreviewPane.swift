import SwiftUI

public struct PreviewPane: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel
    @State private var mode: Mode = .preview

    enum Mode: String, CaseIterable, Identifiable {
        case preview = "Preview"
        case code = "Code"
        var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            switch mode {
            case .preview:
                WebView(html: viewModel.extractedHTML)
            case .code:
                ScrollView {
                    Text(viewModel.extractedHTML)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }
}
