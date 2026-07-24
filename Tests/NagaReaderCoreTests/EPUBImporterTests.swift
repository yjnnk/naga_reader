import XCTest
@testable import NagaReaderCore

final class EPUBImporterTests: XCTestCase {
    func testImportsEPUBIntoAppStorageAndRecordsCurrentBook() throws {
        let source = try makeTemporaryEPUB(named: "Fixture Book.epub")
        let storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let importer = EPUBImporter(storageDirectory: storageDirectory)

        let record = try importer.importBook(from: source)

        XCTAssertEqual(record.title, "Fixture Book")
        XCTAssertEqual(record.originalFileName, "Fixture Book.epub")
        XCTAssertTrue(FileManager.default.fileExists(atPath: record.storedURL.path))
        XCTAssertTrue(record.storedURL.path.hasPrefix(storageDirectory.path))
    }

    func testRejectsNonEPUBFiles() throws {
        let source = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")
        try "not an epub".write(to: source, atomically: true, encoding: .utf8)
        let importer = EPUBImporter(
            storageDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
        )

        XCTAssertThrowsError(try importer.importBook(from: source)) { error in
            XCTAssertEqual(error as? EPUBImportError, .unsupportedFileType)
        }
    }

    func testImportsSameFileNameAsDistinctStoredBooks() throws {
        let first = try makeTemporaryEPUB(named: "Book.epub")
        let second = try makeTemporaryEPUB(named: "Book.epub")
        let storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let importer = EPUBImporter(storageDirectory: storageDirectory)

        let firstRecord = try importer.importBook(from: first)
        let secondRecord = try importer.importBook(from: second)

        XCTAssertNotEqual(firstRecord.id, secondRecord.id)
        XCTAssertNotEqual(firstRecord.storedURL, secondRecord.storedURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: firstRecord.storedURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondRecord.storedURL.path))
    }

    private func makeTemporaryEPUB(named fileName: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent(fileName)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("fixture".utf8).write(to: url)
        return url
    }
}
