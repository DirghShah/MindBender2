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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(usage.used.formatted()) / \(usage.limit.formatted()) tokens")
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Text("\(usage.remaining.formatted()) left")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
                ProgressView(value: progressValue(usage))
                    .tint(progressTint(usage))
            }
            .padding(.vertical, 4)
        } else if isLoadingUsage {
            HStack {
                ProgressView().controlSize(.small)
                Text("Loading…").foregroundStyle(.secondary)
            }
        } else if let usageError {
            Text(usageError)
                .foregroundStyle(.red)
                .font(.callout)
        } else {
            Text("No usage data yet.").foregroundStyle(.secondary)
        }

        Button {
            loadUsage()
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
        .disabled(isLoadingUsage)
    }

    private func progressValue(_ u: UsageResponse) -> Double {
        guard u.limit > 0 else { return 0 }
        return min(1.0, Double(u.used) / Double(u.limit))
    }

    private func progressTint(_ u: UsageResponse) -> Color {
        let p = progressValue(u)
        if p >= 0.9 { return .red }
        if p >= 0.7 { return .orange }
        return .green
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
