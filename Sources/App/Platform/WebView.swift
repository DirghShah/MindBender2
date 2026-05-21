import SwiftUI
import WebKit

#if os(macOS)
public typealias PlatformViewRepresentable = NSViewRepresentable
#else
public typealias PlatformViewRepresentable = UIViewRepresentable
#endif

public struct WebView: PlatformViewRepresentable {
    public let html: String

    public init(html: String) { self.html = html }

    // Non-nil https base URL so remote <img>/CSS are allowed by WKWebView's origin checks.
    private static let baseURL = URL(string: "https://localhost/")!

    public final class Coordinator {
        var lastHTML: String = ""
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    private func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        #if os(iOS)
        webView.scrollView.bounces = false
        #endif
        return webView
    }

    private func loadIfChanged(_ webView: WKWebView, context: Context) {
        guard context.coordinator.lastHTML != html else { return }
        context.coordinator.lastHTML = html
        webView.loadHTMLString(html, baseURL: Self.baseURL)
    }

    #if os(macOS)
    public func makeNSView(context: Context) -> WKWebView {
        let v = makeWebView()
        loadIfChanged(v, context: context)
        return v
    }
    public func updateNSView(_ nsView: WKWebView, context: Context) {
        loadIfChanged(nsView, context: context)
    }
    #else
    public func makeUIView(context: Context) -> WKWebView {
        let v = makeWebView()
        loadIfChanged(v, context: context)
        return v
    }
    public func updateUIView(_ uiView: WKWebView, context: Context) {
        loadIfChanged(uiView, context: context)
    }
    #endif
}
