import SwiftUI
import PhotosUI

public struct ImagePickerButton: View {
    @Binding public var imageData: Data?
    public let label: String

    @State private var selection: PhotosPickerItem?

    public init(imageData: Binding<Data?>, label: String = "Choose Target Image") {
        self._imageData = imageData
        self.label = label
    }

    public var body: some View {
        PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
            Label(label, systemImage: "photo.on.rectangle")
        }
        .onChange(of: selection) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    await MainActor.run { imageData = data }
                }
            }
        }
    }
}
