import XCTest
@testable import NagaReaderCore

final class ChapterContentLoaderTests: XCTestCase {
    func testLoadsBodyForChapterHref() throws {
        let epubURL = try EPUBFixture.makeReflowableEPUB()
        let extractionURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let parsed = try EPUBParser().parse(epubURL: epubURL, extractingTo: extractionURL)
        let loader = ChapterContentLoader(parsedEPUB: parsed)

        let content = try loader.loadChapterBody(href: "chapters/chapter1.xhtml")

        XCTAssertEqual(content.baseURL, extractionURL.appendingPathComponent("OEBPS/chapters", isDirectory: true))
        XCTAssertTrue(content.body.contains("<h1>Chapter One</h1><p>Hello from EPUB.</p>"))
    }
}
