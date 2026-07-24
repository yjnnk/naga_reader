import XCTest
@testable import NagaReaderCore

final class ReadingDocumentBuilderTests: XCTestCase {
    func testBuildsCenteredReadingDocumentWithConstrainedImages() {
        let html = ReadingDocumentBuilder().buildDocument(
            chapterBody: "<h1>Chapter One</h1><p style=\"width:100vw\">Hello</p><img src=\"image.png\">"
        )

        XCTAssertTrue(html.contains("<main class=\"reader\">"))
        XCTAssertTrue(html.contains("max-width: 680px;"))
        XCTAssertTrue(html.contains("margin: 0 auto;"))
        XCTAssertTrue(html.contains(".reader, .reader * {"))
        XCTAssertTrue(html.contains("max-width: 100% !important;"))
        XCTAssertTrue(html.contains("overflow-wrap: break-word;"))
        XCTAssertTrue(html.contains("img {"))
        XCTAssertTrue(html.contains("height: auto !important;"))
        XCTAssertFalse(html.contains("display: block;"))
        XCTAssertTrue(html.contains("<h1>Chapter One</h1><p style=\"width:100vw\">Hello</p><img src=\"image.png\">"))
    }
}
