import SwiftUI

public struct SettingsSheet: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var urlString: String = ""
    @State private var validationMessage: String?

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Proxy server URL") {
                    TextField("http://localhost:8080", text: $urlString)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                    if let validationMessage {
                        Text(validationMessage).foregroundStyle(.red).font(.callout)
                    }
                    Text("The teacher runs the Vapor proxy and supplies its address. Use the laptop's LAN IP (e.g. http://192.168.1.42:8080) so iPads can reach it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear { urlString = viewModel.proxyBaseURL.absoluteString }
        }
    }

    private func save() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme,
              scheme == "http" || scheme == "https" else {
            validationMessage = "Enter a full URL starting with http:// or https://"
            return
        }
        viewModel.proxyBaseURL = url
        dismiss()
    }
}
