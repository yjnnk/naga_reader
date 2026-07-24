import XCTest
@testable import NagaReaderCore

final class ReadingPositionStoreTests: XCTestCase {
    func testMissingPositionFileReturnsEmptyPositions() throws {
        let store = ReadingPositionStore(fileURL: temporaryJSONURL())

        XCTAssertEqual(try store.load(), .empty)
    }

    func testSavesReadingPositionPerBook() throws {
        let store = ReadingPositionStore(fileURL: temporaryJSONURL())

        try store.save(ReadingPosition(chapterHref: "one.xhtml", progress: 0.25), for: "book-one")
        try store.save(ReadingPosition(chapterHref: "two.xhtml", progress: 0.75), for: "book-two")

        XCTAssertEqual(
            try store.position(for: "book-one"),
            ReadingPosition(chapterHref: "one.xhtml", progress: 0.25)
        )
        XCTAssertEqual(
            try store.position(for: "book-two"),
            ReadingPosition(chapterHref: "two.xhtml", progress: 0.75)
        )
    }

    func testReadingPositionClampsProgress() {
        XCTAssertEqual(ReadingPosition(chapterHref: "start.xhtml", progress: -1).progress, 0)
        XCTAssertEqual(ReadingPosition(chapterHref: "end.xhtml", progress: 2).progress, 1)
    }

    private func temporaryJSONURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }
}
