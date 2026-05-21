import XCTest
@testable import Shared

final class HTMLExtractorTests: XCTestCase {
    func testFencedHtmlBlock() {
        let reply = """
        Sure! Here is your page:
        ```html
        <!DOCTYPE html>
        <html><body><h1>Hi</h1></body></html>
        ```
        """
        let html = HTMLExtractor.extract(from: reply)
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<h1>Hi</h1>"))
    }

    func testFencedHtmlBlockCaseInsensitive() {
        let reply = """
        ```HTML
        <html><body>x</body></html>
        ```
        """
        let html = HTMLExtractor.extract(from: reply)
        XCTAssertTrue(html.contains("<html>"))
    }

    func testUngroupedFenceContainingHTML() {
        let reply = """
        ```
        <!DOCTYPE html>
        <html><body>noted</body></html>
        ```
        """
        let html = HTMLExtractor.extract(from: reply)
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE html>"))
    }

    func testNoFenceButRawHTML() {
        let reply = "<!DOCTYPE html><html><body>raw</body></html>"
        let html = HTMLExtractor.extract(from: reply)
        XCTAssertTrue(html.contains("raw"))
    }

    func testNoHTMLAtAllGetsWrapped() {
        let reply = "I cannot do that."
        let html = HTMLExtractor.extract(from: reply)
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("I cannot do that."))
    }

    func testEmptyReplyGetsWrapped() {
        let html = HTMLExtractor.extract(from: "")
        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("(no reply)"))
    }

    func testEscapesAngleBracketsInFallback() {
        let reply = "Here is some <bad> markup"
        let html = HTMLExtractor.extract(from: reply)
        XCTAssertTrue(html.contains("&lt;bad&gt;"))
    }
}
