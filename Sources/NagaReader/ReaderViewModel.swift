import Foundation
import NagaReaderCore

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published private(set) var shellState = AppShellState.empty
    @Published private(set) var library = LibraryState.empty
    @Published private(set) var readerSession: ReaderSession?
    @Published var errorMessage: String?

    var currentBook: ImportedBookRecord? {
        readerSession?.currentBook
    }

    var tableOfContents: [ReaderSession.TableOfContentsEntry] {
        readerSession?.tableOfContents ?? []
    }

    var selectedChapter: EPUBChapter? {
        readerSession?.selectedChapter
    }

    private let importer: EPUBImporter
    private let libraryStore: LibraryStore

    init(directories: AppDirectories = .live) {
        self.importer = EPUBImporter(storageDirectory: directories.books)
        self.libraryStore = LibraryStore(fileURL: directories.library)
    }

    func load() {
        do {
            library = try libraryStore.load()
            let currentBook = library.currentBookID.flatMap { currentID in
                library.recentBooks.first { $0.id == currentID }
            }
            readerSession = currentBook.map(ReaderSession.open)
        } catch {
            errorMessage = "Não foi possível carregar a biblioteca local. \(error.localizedDescription)"
        }
    }

    func importBook(from sourceURL: URL) {
        do {
            let book = try importer.importBook(from: sourceURL)
            try libraryStore.recordImportedBook(book)
            library = try libraryStore.load()
            readerSession = ReaderSession.open(book)
        } catch {
            errorMessage = "Não foi possível importar este EPUB. \(error.localizedDescription)"
        }
    }

    func selectTableOfContentsEntry(id: Int) {
        readerSession?.selectEntry(id: id)
    }

    func isSelectedTableOfContentsEntry(_ entry: ReaderSession.TableOfContentsEntry) -> Bool {
        readerSession?.selectedEntryID == entry.id
    }
}
