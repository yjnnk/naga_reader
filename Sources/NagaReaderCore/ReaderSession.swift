import Foundation

public struct ReaderSession: Equatable {
    public struct TableOfContentsEntry: Equatable, Identifiable {
        public let id: Int
        public let chapter: EPUBChapter
    }

    public let currentBook: ImportedBookRecord
    public private(set) var selectedEntryID: Int?

    public var tableOfContents: [TableOfContentsEntry] {
        let chapters: [EPUBChapter] = currentBook.chapters.isEmpty
            ? currentBook.spineHrefs.map { EPUBChapter(title: Self.fallbackTitle(for: $0), href: $0) }
            : currentBook.chapters
        return chapters.enumerated().map { index, chapter in
            TableOfContentsEntry(id: index, chapter: chapter)
        }
    }

    public var selectedChapter: EPUBChapter? {
        guard let selectedEntryID else {
            return nil
        }

        return tableOfContents.first { $0.id == selectedEntryID }?.chapter
    }

    public static func open(_ book: ImportedBookRecord, position: ReadingPosition? = nil) -> ReaderSession {
        let entries = tableOfContents(for: book)
        let restoredEntryID = position.flatMap { savedPosition in
            entries.first { $0.chapter.href == savedPosition.chapterHref }?.id
        }
        return ReaderSession(currentBook: book, selectedEntryID: restoredEntryID ?? entries.first?.id)
    }

    public mutating func selectEntry(id: Int) {
        guard tableOfContents.contains(where: { $0.id == id }) else {
            return
        }

        selectedEntryID = id
    }

    private static func tableOfContents(for book: ImportedBookRecord) -> [TableOfContentsEntry] {
        let chapters: [EPUBChapter] = book.chapters.isEmpty
            ? book.spineHrefs.map { EPUBChapter(title: fallbackTitle(for: $0), href: $0) }
            : book.chapters
        return chapters.enumerated().map { index, chapter in
            TableOfContentsEntry(id: index, chapter: chapter)
        }
    }

    private static func fallbackTitle(for href: String) -> String {
        href.split(separator: "/").last?
            .split(separator: ".").first?
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized ?? href
    }
}
