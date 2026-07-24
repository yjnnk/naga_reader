import XCTest
@testable import NagaReaderCore

final class ReadingDocumentBuilderTests: XCTestCase {
    func testBuildsCenteredReadingDocumentWithConstrainedImages() {
        let settings = ReadingSettings(
            columnWidth: 620,
            pageMargin: 88,
            fontSize: 21,
            lineHeight: 1.7,
            theme: .dark,
            readingMode: .paged,
            fontFamily: .palatino
        )
        let html = ReadingDocumentBuilder().buildDocument(
            chapterBody: "<h1>Chapter One</h1><p style=\"width:100vw\">Hello</p><img src=\"image.png\">",
            settings: settings
        )

        XCTAssertTrue(html.contains("<main class=\"reader\">"))
        XCTAssertTrue(html.contains("max-width: 620px;"))
        XCTAssertTrue(html.contains("padding: 88px;"))
        XCTAssertTrue(html.contains("font: 21px"))
        XCTAssertTrue(html.contains("\"Palatino\", \"Palatino Linotype\", Georgia, serif;"))
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

    func testDefaultDocumentUsesSimplePagination() {
        let html = ReadingDocumentBuilder().buildDocument(
            chapterBody: "<p>Hello</p>",
            settings: .default
        )

        XCTAssertTrue(html.contains("overflow: hidden;"))
        XCTAssertTrue(html.contains("overflow-x: hidden;"))
        XCTAssertTrue(html.contains("overflow-y: hidden;"))
        XCTAssertTrue(html.contains("width: 100%;"))
        XCTAssertTrue(html.contains("max-width: 824px;"))
        XCTAssertTrue(html.contains("column-width: 680px;"))
        XCTAssertTrue(html.contains("column-gap: 144px;"))
        XCTAssertTrue(html.contains("column-fill: auto;"))
        XCTAssertTrue(html.contains("height: calc(100vh - 144px);"))
        XCTAssertTrue(html.contains("scroll-snap-type: x mandatory;"))
        XCTAssertFalse(html.contains("scroll-behavior: smooth;"))
    }

    func testScrollModeUsesContinuousVerticalReading() {
        let html = ReadingDocumentBuilder().buildDocument(
            chapterBody: "<p>Hello</p>",
            settings: .default.with(readingMode: .scroll)
        )

        XCTAssertTrue(html.contains("overflow-y: auto;"))
        XCTAssertTrue(html.contains("min-height: calc(100vh - 144px);"))
        XCTAssertFalse(html.contains("column-width: 680px;"))
        XCTAssertTrue(html.contains("max-width: 680px;"))
    }

    func testDocumentAppliesConfiguredFontFallbackStack() {
        let html = ReadingDocumentBuilder().buildDocument(
            chapterBody: "<p>Hello</p>",
            settings: .default.with(fontFamily: .menlo)
        )

        XCTAssertTrue(html.contains("font: 19px Menlo, Monaco, Consolas, monospace;"))
    }
}
