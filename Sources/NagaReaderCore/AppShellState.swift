import Foundation

public struct AppShellState: Equatable {
    public let sidebarTitle: String
    public let readerTitle: String
    public let readerMessage: String
    public let canShowTableOfContents: Bool

    public static let empty = AppShellState(
        sidebarTitle: "Sumário",
        readerTitle: "Naga Reader",
        readerMessage: "Abra um EPUB local para começar. O livro fica salvo neste Mac e reabre na última posição.",
        canShowTableOfContents: false
    )

    public init(
        sidebarTitle: String,
        readerTitle: String,
        readerMessage: String,
        canShowTableOfContents: Bool
    ) {
        self.sidebarTitle = sidebarTitle
        self.readerTitle = readerTitle
        self.readerMessage = readerMessage
        self.canShowTableOfContents = canShowTableOfContents
    }
}
