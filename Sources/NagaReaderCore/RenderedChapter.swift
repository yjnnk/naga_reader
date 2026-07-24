import Foundation

public struct RenderedChapter: Equatable {
    public let chapterHref: String
    public let html: String
    public let baseURL: URL?
    public let restoredProgress: Double

    public init(chapterHref: String, html: String, baseURL: URL?, restoredProgress: Double = 0) {
        self.chapterHref = chapterHref
        self.html = html
        self.baseURL = baseURL
        self.restoredProgress = min(max(restoredProgress, 0), 1)
    }
}
