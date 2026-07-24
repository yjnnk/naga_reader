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
            storedURL: URL(fileURLWithPath: "/tmp/Fixture Book.epub")
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
            storedURL: URL(fileURLWithPath: "/tmp/First.epub")
        )
        let second = ImportedBookRecord(
            id: BookID("second"),
            title: "Second",
            originalFileName: "Second.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Second.epub")
        )

        try store.recordImportedBook(first)
        try store.recordImportedBook(second)
        try store.recordImportedBook(first)

        let library = try store.load()
        XCTAssertEqual(library.currentBookID, first.id)
        XCTAssertEqual(library.recentBooks.map(\.id), [first.id, second.id])
    }
}
