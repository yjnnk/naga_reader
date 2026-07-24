import Foundation
import NagaReaderCore

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published private(set) var shellState = AppShellState.empty
    @Published private(set) var library = LibraryState.empty
    @Published private(set) var readerSession: ReaderSession?
    @Published private(set) var renderedChapter: RenderedChapter?
    @Published private(set) var readingSettings = ReadingSettings.default
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
    private let readingSettingsStore: ReadingSettingsStore
    private let readingPositionStore: ReadingPositionStore
    private let parser = EPUBParser()
    private let documentBuilder = ReadingDocumentBuilder()

    init(directories: AppDirectories = .live) {
        self.importer = EPUBImporter(storageDirectory: directories.books)
        self.libraryStore = LibraryStore(fileURL: directories.library)
        self.readingSettingsStore = ReadingSettingsStore(fileURL: directories.settings)
        self.readingPositionStore = ReadingPositionStore(fileURL: directories.readingPositions)
    }

    func load() {
        do {
            library = try libraryStore.load()
            readingSettings = try readingSettingsStore.load()
            let currentBook = library.currentBookID.flatMap { currentID in
                library.recentBooks.first { $0.id == currentID }
            }
            if let currentBook {
                readerSession = try openSession(for: currentBook)
            }
            try rebuildReaderDocument()
        } catch {
            errorMessage = "Não foi possível carregar a biblioteca local. \(error.localizedDescription)"
        }
    }

    func importBook(from sourceURL: URL) {
        do {
            let book = try importer.importBook(from: sourceURL)
            try libraryStore.recordImportedBook(book)
            library = try libraryStore.load()
            readerSession = try openSession(for: book)
            try rebuildReaderDocument()
        } catch {
            errorMessage = "Não foi possível importar este EPUB. \(error.localizedDescription)"
        }
    }

    func selectTableOfContentsEntry(id: Int) {
        readerSession?.selectEntry(id: id)
        do {
            try saveCurrentPosition(progress: 0)
            try rebuildReaderDocument()
        } catch {
            errorMessage = "Não foi possível carregar este capítulo. \(error.localizedDescription)"
        }
    }

    func isSelectedTableOfContentsEntry(_ entry: ReaderSession.TableOfContentsEntry) -> Bool {
        readerSession?.selectedEntryID == entry.id
    }

    func updateReadingSettings(_ update: (ReadingSettings) -> ReadingSettings) {
        readingSettings = update(readingSettings)
        do {
            try readingSettingsStore.save(readingSettings)
            try rebuildReaderDocument()
        } catch {
            errorMessage = "Não foi possível salvar as configurações de leitura. \(error.localizedDescription)"
        }
    }

    func updateReadingProgress(chapterHref: String, progress: Double) {
        do {
            try saveCurrentPosition(chapterHref: chapterHref, progress: progress)
        } catch {
            errorMessage = "Não foi possível salvar a posição de leitura. \(error.localizedDescription)"
        }
    }

    private func rebuildReaderDocument() throws {
        guard let book = currentBook, let chapter = selectedChapter else {
            renderedChapter = nil
            return
        }

        let extractionURL = book.storedURL
            .deletingLastPathComponent()
            .appendingPathComponent("extracted", isDirectory: true)
        let parsed = try parser.parse(epubURL: book.storedURL, extractingTo: extractionURL)
        let content = try ChapterContentLoader(parsedEPUB: parsed).loadChapterBody(href: chapter.href)
        let savedPosition = try readingPositionStore.position(for: book.id)
        let restoredProgress = savedPosition?.chapterHref == chapter.href ? savedPosition?.progress ?? 0 : 0
        renderedChapter = RenderedChapter(
            chapterHref: chapter.href,
            html: documentBuilder.buildDocument(chapterBody: content.body, settings: readingSettings),
            baseURL: content.baseURL,
            restoredProgress: restoredProgress
        )
    }

    private func openSession(for book: ImportedBookRecord) throws -> ReaderSession {
        try ReaderSession.open(book, position: readingPositionStore.position(for: book.id))
    }

    private func saveCurrentPosition(progress: Double) throws {
        guard let chapterHref = selectedChapter?.href else {
            return
        }

        try saveCurrentPosition(chapterHref: chapterHref, progress: progress)
    }

    private func saveCurrentPosition(chapterHref: String, progress: Double) throws {
        guard let book = currentBook, let chapter = selectedChapter else {
            return
        }
        guard chapter.href == chapterHref else {
            return
        }

        try readingPositionStore.save(
            ReadingPosition(chapterHref: chapter.href, progress: progress),
            for: book.id
        )
    }
}
