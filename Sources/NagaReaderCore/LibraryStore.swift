import Foundation

public struct LibraryState: Equatable, Codable {
    public var currentBookID: BookID?
    public var recentBooks: [ImportedBookRecord]

    public static let empty = LibraryState(currentBookID: nil, recentBooks: [])

    public init(currentBookID: BookID?, recentBooks: [ImportedBookRecord]) {
        self.currentBookID = currentBookID
        self.recentBooks = recentBooks
    }
}

public struct LibraryStore {
    private let store: JSONFileStore<LibraryState>

    public init(fileURL: URL) {
        self.store = JSONFileStore(fileURL: fileURL)
    }

    public func load() throws -> LibraryState {
        try store.load(default: .empty)
    }

    public func save(_ state: LibraryState) throws {
        try store.save(state)
    }

    public func recordImportedBook(_ book: ImportedBookRecord) throws {
        var state = try load()
        state.recentBooks.removeAll { $0.id == book.id }
        state.recentBooks.insert(book, at: 0)
        state.currentBookID = book.id
        try save(state)
    }

    public func selectRecentBook(id: BookID) throws -> ImportedBookRecord? {
        var state = try load()
        guard let index = state.recentBooks.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        let book = state.recentBooks.remove(at: index)
        state.recentBooks.insert(book, at: 0)
        state.currentBookID = book.id
        try save(state)
        return book
    }

    public func removeRecentBook(id: BookID) throws {
        var state = try load()
        state.recentBooks.removeAll { $0.id == id }
        if state.currentBookID == id {
            state.currentBookID = state.recentBooks.first?.id
        }
        try save(state)
    }
}
