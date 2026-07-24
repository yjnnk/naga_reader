import XCTest
@testable import NagaReaderCore

final class EPUBImporterTests: XCTestCase {
    func testImportsEPUBIntoAppStorageAndRecordsCurrentBook() throws {
        let source = try EPUBFixture.makeReflowableEPUB()
        let storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let importer = EPUBImporter(storageDirectory: storageDirectory)

        let record = try importer.importBook(from: source)

        XCTAssertEqual(record.title, "Fixture Book")
        XCTAssertEqual(record.originalFileName, source.lastPathComponent)
        XCTAssertEqual(record.packagePath, "OEBPS/content.opf")
        XCTAssertEqual(record.manifest["chapter1"]?.href, "chapters/chapter1.xhtml")
        XCTAssertEqual(record.manifest["cover"]?.mediaType, "image/jpeg")
        XCTAssertEqual(record.spineHrefs, ["chapters/chapter1.xhtml"])
        XCTAssertEqual(record.chapters, [EPUBChapter(title: "Chapter One", href: "chapters/chapter1.xhtml")])
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
        let first = try EPUBFixture.makeReflowableEPUB(title: "Book")
        let second = try EPUBFixture.makeReflowableEPUB(title: "Book")
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

    func testRejectsFixedLayoutEPUBDuringImport() throws {
        let source = try EPUBFixture.makeFixedLayoutEPUB()
        let storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let importer = EPUBImporter(storageDirectory: storageDirectory)

        XCTAssertThrowsError(try importer.importBook(from: source)) { error in
            XCTAssertEqual(error as? EPUBParseError, .unsupportedFixedLayout)
        }
    }
}
