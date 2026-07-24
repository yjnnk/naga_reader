import XCTest
@testable import NagaReaderCore

final class EPUBParserTests: XCTestCase {
    func testParsesMetadataManifestAndSpineFromReflowableEPUB() throws {
        let epubURL = try EPUBFixture.makeReflowableEPUB()
        let extractionURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        let parsed = try EPUBParser().parse(epubURL: epubURL, extractingTo: extractionURL)

        XCTAssertEqual(parsed.title, "Fixture Book")
        XCTAssertEqual(parsed.packagePath, "OEBPS/content.opf")
        XCTAssertEqual(parsed.spineHrefs, ["chapters/chapter1.xhtml"])
        XCTAssertEqual(parsed.manifest["chapter1"]?.href, "chapters/chapter1.xhtml")
        XCTAssertEqual(parsed.manifest["chapter1"]?.mediaType, "application/xhtml+xml")
        XCTAssertEqual(parsed.manifest["style"]?.href, "styles/book.css")
        XCTAssertEqual(parsed.chapters, [EPUBChapter(title: "Chapter One", href: "chapters/chapter1.xhtml")])
    }

    func testMatchesNavigationEntriesWithFragmentsToSpineItems() throws {
        let epubURL = try EPUBFixture.makeReflowableEPUB(navHref: "chapters/chapter1.xhtml#start")
        let extractionURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        let parsed = try EPUBParser().parse(epubURL: epubURL, extractingTo: extractionURL)

        XCTAssertEqual(parsed.chapters, [EPUBChapter(title: "Chapter One", href: "chapters/chapter1.xhtml")])
    }

    func testRejectsFixedLayoutEPUB() throws {
        let epubURL = try EPUBFixture.makeFixedLayoutEPUB()
        let extractionURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        XCTAssertThrowsError(try EPUBParser().parse(epubURL: epubURL, extractingTo: extractionURL)) { error in
            XCTAssertEqual(error as? EPUBParseError, .unsupportedFixedLayout)
        }
    }

    func testRejectsSpineItemsMissingFromManifest() throws {
        let epubURL = try EPUBFixture.makeEPUBWithBrokenSpine()
        let extractionURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        XCTAssertThrowsError(try EPUBParser().parse(epubURL: epubURL, extractingTo: extractionURL)) { error in
            XCTAssertEqual(error as? EPUBParseError, .unresolvedSpineItem("missing"))
        }
    }
}
