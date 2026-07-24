import XCTest
@testable import NagaReaderCore

final class ReadingSettingsStoreTests: XCTestCase {
    func testMissingSettingsReturnsDefaultSettings() throws {
        let store = ReadingSettingsStore(fileURL: temporaryJSONURL())

        XCTAssertEqual(try store.load(), .default)
    }

    func testSavesAndLoadsGlobalReadingSettings() throws {
        let store = ReadingSettingsStore(fileURL: temporaryJSONURL())
        let settings = ReadingSettings(
            columnWidth: 620,
            pageMargin: 88,
            fontSize: 21,
            lineHeight: 1.7,
            theme: .dark
        )

        try store.save(settings)

        XCTAssertEqual(try store.load(), settings)
    }

    private func temporaryJSONURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }
}
