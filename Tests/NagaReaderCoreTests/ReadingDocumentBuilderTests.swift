import XCTest
@testable import NagaReaderCore

final class ReadingDocumentBuilderTests: XCTestCase {
    func testBuildsCenteredReadingDocumentWithConstrainedImages() {
        let settings = ReadingSettings(
            columnWidth: 620,
            pageMargin: 88,
            fontSize: 21,
            lineHeight: 1.7,
            theme: .dark
        )
        let html = ReadingDocumentBuilder().buildDocument(
            chapterBody: "<h1>Chapter One</h1><p style=\"width:100vw\">Hello</p><img src=\"image.png\">",
            settings: settings
        )

        XCTAssertTrue(html.contains("<main class=\"reader\">"))
        XCTAssertTrue(html.contains("max-width: 620px;"))
        XCTAssertTrue(html.contains("padding: 88px;"))
        XCTAssertTrue(html.contains("font: 21px"))
        XCTAssertTrue(html.contains("line-height: 1.7;"))
        XCTAssertTrue(html.contains("background: #101114;"))
        XCTAssertTrue(html.contains("margin: 0 auto;"))
        XCTAssertFalse(html.contains(".reader, .reader * {"))
        XCTAssertTrue(html.contains(".reader * {"))
        XCTAssertTrue(html.contains("max-width: 100% !important;"))
        XCTAssertTrue(html.contains("overflow-wrap: break-word;"))
        XCTAssertTrue(html.contains("img {"))
        XCTAssertTrue(html.contains("height: auto !important;"))
        XCTAssertFalse(html.contains("display: block;"))
        XCTAssertTrue(html.contains("<h1>Chapter One</h1><p style=\"width:100vw\">Hello</p><img src=\"image.png\">"))
    }
}
