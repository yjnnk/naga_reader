import Foundation

struct AppDirectories {
    let base: URL

    static var live: AppDirectories {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? FileManager.default.temporaryDirectory
        return AppDirectories(base: support.appendingPathComponent("NagaReader", isDirectory: true))
    }

    var books: URL {
        base.appendingPathComponent("Books", isDirectory: true)
    }

    var library: URL {
        base.appendingPathComponent("library.json")
    }

    var settings: URL {
        base.appendingPathComponent("settings.json")
    }

    var readingPositions: URL {
        base.appendingPathComponent("reading-positions.json")
    }
}
