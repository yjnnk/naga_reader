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
            theme: .dark,
            readingMode: .scroll
        )

        try store.save(settings)

        XCTAssertEqual(try store.load(), settings)
    }

    func testLoadsSettingsWrittenBeforeReadingModeExisted() throws {
        let fileURL = temporaryJSONURL()
        let legacyJSON = """
        {
          "columnWidth": 640,
          "pageMargin": 80,
          "fontSize": 20,
          "lineHeight": 1.6,
          "theme": "dark"
        }
        """
        try legacyJSON.data(using: .utf8)?.write(to: fileURL)
        let store = ReadingSettingsStore(fileURL: fileURL)

        XCTAssertEqual(
            try store.load(),
            ReadingSettings(
                columnWidth: 640,
                pageMargin: 80,
                fontSize: 20,
                lineHeight: 1.6,
                theme: .dark,
                readingMode: .paged
            )
        )
    }

    private func temporaryJSONURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }
}
