import Foundation

public struct ReadingSettingsStore {
    private let store: JSONFileStore<ReadingSettings>

    public init(fileURL: URL) {
        self.store = JSONFileStore(fileURL: fileURL)
    }

    public func load() throws -> ReadingSettings {
        try store.load(default: .default)
    }

    public func save(_ settings: ReadingSettings) throws {
        try store.save(settings)
    }
}
