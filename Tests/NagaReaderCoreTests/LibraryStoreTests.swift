import XCTest
@testable import NagaReaderCore

final class LibraryStoreTests: XCTestCase {
    func testRecordingImportedBookMakesItCurrentAndRecent() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let store = LibraryStore(fileURL: storeURL)
        let book = ImportedBookRecord(
            id: BookID("fixture-book"),
            title: "Fixture Book",
            originalFileName: "Fixture Book.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Fixture Book.epub"),
            packagePath: "OEBPS/content.opf",
            manifest: [
                "chapter1": EPUBManifestItem(id: "chapter1", href: "chapters/chapter1.xhtml", mediaType: "application/xhtml+xml", properties: "")
            ],
            spineHrefs: ["chapters/chapter1.xhtml"],
            chapters: [EPUBChapter(title: "Chapter One", href: "chapters/chapter1.xhtml")]
        )

        try store.recordImportedBook(book)

        let library = try store.load()
        XCTAssertEqual(library.currentBookID, book.id)
        XCTAssertEqual(library.recentBooks, [book])
    }

    func testRecordingSameBookMovesItToFrontWithoutDuplicates() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let store = LibraryStore(fileURL: storeURL)
        let first = ImportedBookRecord(
            id: BookID("first"),
            title: "First",
            originalFileName: "First.epub",
            storedURL: URL(fileURLWithPath: "/tmp/First.epub"),
            packagePath: "OEBPS/content.opf",
            spineHrefs: ["chapters/first.xhtml"]
        )
        let second = ImportedBookRecord(
            id: BookID("second"),
            title: "Second",
            originalFileName: "Second.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Second.epub"),
            packagePath: "OEBPS/content.opf",
            spineHrefs: ["chapters/second.xhtml"]
        )

        try store.recordImportedBook(first)
        try store.recordImportedBook(second)
        try store.recordImportedBook(first)

        let library = try store.load()
        XCTAssertEqual(library.currentBookID, first.id)
        XCTAssertEqual(library.recentBooks.map(\.id), [first.id, second.id])
    }

    func testLoadsBookRecordsWrittenBeforePackageMetadataExisted() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        try """
        {
          "currentBookID" : { "rawValue" : "legacy" },
          "recentBooks" : [
            {
              "id" : { "rawValue" : "legacy" },
              "title" : "Legacy",
              "originalFileName" : "Legacy.epub",
              "storedURL" : "file:\\/\\/\\/tmp\\/Legacy.epub"
            }
          ]
        }
        """.write(to: storeURL, atomically: true, encoding: .utf8)

        let library = try LibraryStore(fileURL: storeURL).load()

        XCTAssertEqual(library.recentBooks.first?.packagePath, nil)
        XCTAssertEqual(library.recentBooks.first?.manifest, [:])
        XCTAssertEqual(library.recentBooks.first?.spineHrefs, [])
        XCTAssertEqual(library.recentBooks.first?.chapters, [])
    }
}
