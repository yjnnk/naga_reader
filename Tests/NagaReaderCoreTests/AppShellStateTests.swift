import XCTest
@testable import NagaReaderCore

final class AppShellStateTests: XCTestCase {
    func testEmptyShellIsReadyBeforeABookIsImported() {
        let state = AppShellState.empty

        XCTAssertEqual(state.sidebarTitle, "Sumário")
        XCTAssertEqual(state.readerTitle, "Naga Reader")
        XCTAssertEqual(
            state.readerMessage,
            "Abra um EPUB local para começar. O livro fica salvo neste Mac e reabre na última posição."
        )
        XCTAssertFalse(state.canShowTableOfContents)
    }
}
