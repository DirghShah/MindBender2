import SwiftUI

#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#else
import UIKit
public typealias PlatformImage = UIImage
#endif

public extension Image {
    init?(platformData data: Data) {
        guard let image = PlatformImage(data: data) else { return nil }
        #if os(macOS)
        self = Image(nsImage: image)
        #else
        self = Image(uiImage: image)
        #endif
    }
}
