import SwiftUI
import Shared

public struct SettingsSheet: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var urlString: String = ""
    @State private var validationMessage: String?

    @State private var usage: UsageResponse?
    @State private var usageError: String?
    @State private var isLoadingUsage = false

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
                    Text("Use the laptop's LAN IP (e.g. http://192.168.1.42:8080) or your deployed proxy URL.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Daily token usage") {
                    usageSection
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
            .onAppear {
                urlString = viewModel.proxyBaseURL.absoluteString
                loadUsage()
            }
        }
    }

    @ViewBuilder
    private var usageSection: some View {
        if let usage {
            Text("\(usage.used.formatted()) / \(usage.limit.formatted())")
                .font(.system(.body, design: .monospaced))
        } else if isLoadingUsage {
            Text("Loading…").foregroundStyle(.secondary)
        } else if usageError != nil {
            Text("Not available").foregroundStyle(.secondary)
        } else {
            Text("—").foregroundStyle(.secondary)
        }

        Button("Refresh", action: loadUsage).disabled(isLoadingUsage)
    }

    private func loadUsage() {
        isLoadingUsage = true
        usageError = nil
        Task {
            do {
                let result = try await viewModel.fetchUsage()
                await MainActor.run {
                    usage = result
                    isLoadingUsage = false
                }
            } catch {
                await MainActor.run {
                    usageError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    isLoadingUsage = false
                }
            }
        }
    }

    private func save() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme,
              scheme == "http" || scheme == "https" else {
            validationMessage = "Enter a full URL starting with http:// or https://"
            return
        }
        viewModel.proxyBaseURL = url
        dismiss()
    }
}
