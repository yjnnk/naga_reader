import XCTest
@testable import NagaReaderCore

final class ReaderSessionTests: XCTestCase {
    func testOpeningBookSelectsFirstChapter() {
        let first = EPUBChapter(title: "Chapter One", href: "chapters/one.xhtml")
        let second = EPUBChapter(title: "Chapter Two", href: "chapters/two.xhtml")
        let book = ImportedBookRecord(
            id: "book",
            title: "Book",
            originalFileName: "Book.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Book.epub"),
            chapters: [first, second]
        )

        let session = ReaderSession.open(book)

        XCTAssertEqual(session.currentBook, book)
        XCTAssertEqual(session.tableOfContents.map(\.chapter), [first, second])
        XCTAssertEqual(session.selectedChapter, first)
    }

    func testSelectingChapterUpdatesActiveChapter() {
        let first = EPUBChapter(title: "Chapter One", href: "chapters/one.xhtml")
        let second = EPUBChapter(title: "Chapter Two", href: "chapters/two.xhtml")
        let book = ImportedBookRecord(
            id: "book",
            title: "Book",
            originalFileName: "Book.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Book.epub"),
            chapters: [first, second]
        )
        var session = ReaderSession.open(book)

        session.selectEntry(id: 1)

        XCTAssertEqual(session.selectedChapter, second)
    }

    func testOpeningBookRestoresChapterFromSavedPosition() {
        let first = EPUBChapter(title: "Chapter One", href: "chapters/one.xhtml")
        let second = EPUBChapter(title: "Chapter Two", href: "chapters/two.xhtml")
        let book = ImportedBookRecord(
            id: "book",
            title: "Book",
            originalFileName: "Book.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Book.epub"),
            chapters: [first, second]
        )

        let session = ReaderSession.open(
            book,
            position: ReadingPosition(chapterHref: "chapters/two.xhtml", progress: 0.4)
        )

        XCTAssertEqual(session.selectedChapter, second)
    }

    func testOpeningBookIgnoresSavedPositionForUnknownChapter() {
        let first = EPUBChapter(title: "Chapter One", href: "chapters/one.xhtml")
        let book = ImportedBookRecord(
            id: "book",
            title: "Book",
            originalFileName: "Book.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Book.epub"),
            chapters: [first]
        )

        let session = ReaderSession.open(
            book,
            position: ReadingPosition(chapterHref: "missing.xhtml", progress: 0.4)
        )

        XCTAssertEqual(session.selectedChapter, first)
    }

    func testBookWithoutRichTableOfContentsFallsBackToSpineHrefs() {
        let book = ImportedBookRecord(
            id: "book",
            title: "Book",
            originalFileName: "Book.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Book.epub"),
            spineHrefs: ["chapters/one.xhtml", "chapters/two.xhtml"],
            chapters: []
        )

        let session = ReaderSession.open(book)

        XCTAssertEqual(
            session.tableOfContents.map(\.chapter),
            [
                EPUBChapter(title: "One", href: "chapters/one.xhtml"),
                EPUBChapter(title: "Two", href: "chapters/two.xhtml")
            ]
        )
        XCTAssertEqual(session.selectedChapter?.href, "chapters/one.xhtml")
    }

    func testSelectingUnknownChapterDoesNotChangeActiveChapter() {
        let first = EPUBChapter(title: "Chapter One", href: "chapters/one.xhtml")
        let book = ImportedBookRecord(
            id: "book",
            title: "Book",
            originalFileName: "Book.epub",
            storedURL: URL(fileURLWithPath: "/tmp/Book.epub"),
            chapters: [first]
        )
        var session = ReaderSession.open(book)

        session.selectEntry(id: 99)

        XCTAssertEqual(session.selectedChapter, first)
    }
}
