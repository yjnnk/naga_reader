import Foundation

public struct ReadingPosition: Equatable, Codable {
    public let chapterHref: String
    public let progress: Double

    public init(chapterHref: String, progress: Double) {
        self.chapterHref = chapterHref
        self.progress = min(max(progress, 0), 1)
    }
}

public struct ReadingPositions: Equatable, Codable {
    public var byBookID: [BookID: ReadingPosition]

    public static let empty = ReadingPositions(byBookID: [:])

    public init(byBookID: [BookID: ReadingPosition]) {
        self.byBookID = byBookID
    }
}

public struct ReadingPositionStore {
    private let store: JSONFileStore<ReadingPositions>

    public init(fileURL: URL) {
        self.store = JSONFileStore(fileURL: fileURL)
    }

    public func load() throws -> ReadingPositions {
        try store.load(default: .empty)
    }

    public func position(for bookID: BookID) throws -> ReadingPosition? {
        try load().byBookID[bookID]
    }

    public func save(_ position: ReadingPosition, for bookID: BookID) throws {
        var positions = try load()
        positions.byBookID[bookID] = position
        try store.save(positions)
    }
}
