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
                try openStoredBook(currentBook, missingMessage: "O último EPUB aberto não foi encontrado e foi removido dos recentes.")
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
            readerSession = try openSession(for: book)
            try rebuildReaderDocument()
        } catch {
            errorMessage = readableImportMessage(for: error)
        }
    }

    func openRecentBook(id: BookID) {
        do {
            guard let book = try libraryStore.selectRecentBook(id: id) else {
                library = try libraryStore.load()
                errorMessage = "Este livro não está mais na lista de recentes."
                return
            }
            library = try libraryStore.load()
            try openStoredBook(book, missingMessage: "O arquivo deste EPUB não foi encontrado e foi removido dos recentes.")
        } catch {
            errorMessage = "Não foi possível reabrir este EPUB. \(error.localizedDescription)"
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

    func moveToNextChapter() {
        do {
            guard readerSession?.selectNextEntry() == true else {
                return
            }
            try saveCurrentPosition(progress: 0)
            try rebuildReaderDocument()
        } catch {
            errorMessage = "Não foi possível carregar o próximo capítulo. \(error.localizedDescription)"
        }
    }

    func moveToPreviousChapter() {
        do {
            guard readerSession?.selectPreviousEntry() == true else {
                return
            }
            try saveCurrentPosition(progress: 1)
            try rebuildReaderDocument()
        } catch {
            errorMessage = "Não foi possível carregar o capítulo anterior. \(error.localizedDescription)"
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

    private func openStoredBook(_ book: ImportedBookRecord, missingMessage: String) throws {
        guard FileManager.default.fileExists(atPath: book.storedURL.path) else {
            try removeUnavailableRecentBook(book, message: missingMessage)
            return
        }

        do {
            let parsedBook = try refreshParsedMetadata(for: book)
            readerSession = try openSession(for: parsedBook)
            try rebuildReaderDocument()
        } catch {
            try removeUnavailableRecentBook(
                book,
                message: "Este EPUB não pôde ser lido e foi removido dos recentes. \(error.localizedDescription)"
            )
        }
    }

    private func removeUnavailableRecentBook(_ book: ImportedBookRecord, message: String) throws {
        try libraryStore.removeRecentBook(id: book.id)
        library = try libraryStore.load()
        if currentBook?.id == book.id {
            readerSession = nil
            renderedChapter = nil
        }
        errorMessage = message
    }

    private func refreshParsedMetadata(for book: ImportedBookRecord) throws -> ImportedBookRecord {
        let extractionURL = book.storedURL
            .deletingLastPathComponent()
            .appendingPathComponent("extracted", isDirectory: true)
        let parsed = try parser.parse(epubURL: book.storedURL, extractingTo: extractionURL)
        let refreshedBook = book.withParsedMetadata(parsed)
        try libraryStore.recordImportedBook(refreshedBook)
        library = try libraryStore.load()
        return refreshedBook
    }

    private func readableImportMessage(for error: Error) -> String {
        if let localized = (error as? LocalizedError)?.errorDescription {
            return localized
        }

        return "Não foi possível importar este EPUB. \(error.localizedDescription)"
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
