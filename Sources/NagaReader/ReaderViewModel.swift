import Foundation
import NagaReaderCore

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published private(set) var shellState = AppShellState.empty
    @Published private(set) var library = LibraryState.empty
    @Published private(set) var currentBook: ImportedBookRecord?
    @Published var errorMessage: String?

    private let importer: EPUBImporter
    private let libraryStore: LibraryStore

    init(directories: AppDirectories = .live) {
        self.importer = EPUBImporter(storageDirectory: directories.books)
        self.libraryStore = LibraryStore(fileURL: directories.library)
    }

    func load() {
        do {
            library = try libraryStore.load()
            currentBook = library.currentBookID.flatMap { currentID in
                library.recentBooks.first { $0.id == currentID }
            }
        } catch {
            errorMessage = "Não foi possível carregar a biblioteca local. \(error.localizedDescription)"
        }
    }

    func importBook(from sourceURL: URL) {
        do {
            let book = try importer.importBook(from: sourceURL)
            try libraryStore.recordImportedBook(book)
            library = try libraryStore.load()
            currentBook = book
        } catch {
            errorMessage = "Não foi possível importar este EPUB. \(error.localizedDescription)"
        }
    }
}
