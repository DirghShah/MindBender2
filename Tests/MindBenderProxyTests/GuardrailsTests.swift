import XCTest
@testable import MindBenderProxy

final class GuardrailsTests: XCTestCase {

    // MARK: - Profanity

    func testCleanPromptPasses() {
        XCTAssertFalse(Guardrails.containsBlockedWords("make a blue button that says hello"))
        XCTAssertFalse(Guardrails.containsBlockedWords("a login form with username and password"))
        XCTAssertFalse(Guardrails.containsBlockedWords("class assignment"))
    }

    func testObviousProfanityBlocked() {
        XCTAssertTrue(Guardrails.containsBlockedWords("make a fucking button"))
        XCTAssertTrue(Guardrails.containsBlockedWords("write shit code"))
        XCTAssertTrue(Guardrails.containsBlockedWords("a porn site"))
    }

    func testCaseInsensitive() {
        XCTAssertTrue(Guardrails.containsBlockedWords("FUCK this"))
        XCTAssertTrue(Guardrails.containsBlockedWords("PoRn"))
    }

    func testLeetspeakBlocked() {
        XCTAssertTrue(Guardrails.containsBlockedWords("f0ck"))
        XCTAssertTrue(Guardrails.containsBlockedWords("sh1t"))
        XCTAssertTrue(Guardrails.containsBlockedWords("b1tch"))
    }

    func testRepeatedLettersBlocked() {
        XCTAssertTrue(Guardrails.containsBlockedWords("fuuuck"))
        XCTAssertTrue(Guardrails.containsBlockedWords("shiiiit"))
    }

    func testWordBoundaryReducesFalsePositives() {
        XCTAssertFalse(Guardrails.containsBlockedWords("scunthorpe"))
        XCTAssertFalse(Guardrails.containsBlockedWords("class"))
    }

    // MARK: - HTML sanitation

    func testStripsImgTag() {
        let dirty = "<img src='https://evil.com/x.jpg'><p>hi</p>"
        let clean = Guardrails.sanitizeReply(dirty)
        XCTAssertFalse(clean.contains("<img"))
        XCTAssertTrue(clean.contains("<p>hi</p>"))
    }

    func testStripsIframeAndScript() {
        let dirty = """
        <script>alert(1)</script>
        <iframe src='https://x.com'></iframe>
        <h1>safe</h1>
        """
        let clean = Guardrails.sanitizeReply(dirty)
        XCTAssertFalse(clean.lowercased().contains("<script"))
        XCTAssertFalse(clean.lowercased().contains("<iframe"))
        XCTAssertTrue(clean.contains("<h1>safe</h1>"))
    }

    func testCaseInsensitiveTagStripping() {
        let dirty = "<IMG SRC='x'><Iframe></IFRAME>"
        let clean = Guardrails.sanitizeReply(dirty)
        XCTAssertFalse(clean.lowercased().contains("img"))
        XCTAssertFalse(clean.lowercased().contains("iframe"))
    }

    func testLeavesCleanHTMLAlone() {
        let html = """
        <!DOCTYPE html>
        <html><head><style>body{color:red;}</style></head>
        <body><h1>Hi</h1><p>hello</p></body></html>
        """
        XCTAssertEqual(Guardrails.sanitizeReply(html), html)
    }

    func testStripsMediaTags() {
        let dirty = "<video src='x'></video><audio src='y'></audio><embed src='z'>"
        let clean = Guardrails.sanitizeReply(dirty)
        XCTAssertFalse(clean.lowercased().contains("<video"))
        XCTAssertFalse(clean.lowercased().contains("<audio"))
        XCTAssertFalse(clean.lowercased().contains("<embed"))
    }
}
