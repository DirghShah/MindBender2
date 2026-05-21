import SwiftUI
import UniformTypeIdentifiers

public struct TargetPane: View {
    @EnvironmentObject var viewModel: PlaygroundViewModel
    @Binding var showSettings: Bool
    @Binding var showCompare: Bool
    @State private var confirmNewRound = false

    public init(showSettings: Binding<Bool>, showCompare: Binding<Bool>) {
        self._showSettings = showSettings
        self._showCompare = showCompare
    }

    public var body: some View {
        VStack(spacing: 12) {
            targetImageView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray.opacity(0.2))
                )
                .onDrop(of: [UTType.image, UTType.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                }
                .padding(.horizontal)
                .padding(.top)

            VStack(spacing: 8) {
                ImagePickerButton(imageData: $viewModel.targetImage,
                                  label: viewModel.targetImage == nil ? "Choose Target Image" : "Replace Target")
                    .buttonStyle(.borderedProminent)

                HStack(spacing: 8) {
                    Button { confirmNewRound = true } label: {
                        Label("New Round", systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.messages.isEmpty && viewModel.targetImage == nil)

                    Button(role: .destructive) {
                        viewModel.resetAll()
                    } label: {
                        Label("Reset", systemImage: "trash")
                    }
                }
                .buttonStyle(.bordered)

                Button {
                    showCompare = true
                } label: {
                    Label("Compare", systemImage: "rectangle.split.2x1")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.targetImage == nil)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .confirmationDialog("Start a new round?", isPresented: $confirmNewRound) {
            Button("Keep target image") { viewModel.newRound(keepTarget: true) }
            Button("Swap target image") { viewModel.newRound(keepTarget: false) }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var targetImageView: some View {
        if let data = viewModel.targetImage, let img = Image(platformData: data) {
            img.resizable().scaledToFit().padding(8)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
                Text("Drop a target screen here\nor pick from photos")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.canLoadObject(ofClass: PlatformImage.self) {
            provider.loadObject(ofClass: PlatformImage.self) { object, _ in
                guard let image = object as? PlatformImage else { return }
                #if os(macOS)
                if let tiff = image.tiffRepresentation,
                   let rep = NSBitmapImageRep(data: tiff),
                   let png = rep.representation(using: .png, properties: [:]) {
                    Task { @MainActor in viewModel.targetImage = png }
                }
                #else
                if let png = image.pngData() {
                    Task { @MainActor in viewModel.targetImage = png }
                }
                #endif
            }
            return true
        }
        return false
    }
}
