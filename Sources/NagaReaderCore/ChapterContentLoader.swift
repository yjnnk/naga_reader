import Foundation

public struct ChapterContent: Equatable {
    public let body: String
    public let baseURL: URL

    public init(body: String, baseURL: URL) {
        self.body = body
        self.baseURL = baseURL
    }
}

public struct ChapterContentLoader {
    private let parsedEPUB: ParsedEPUB

    public init(parsedEPUB: ParsedEPUB) {
        self.parsedEPUB = parsedEPUB
    }

    public func loadChapterBody(href: String) throws -> ChapterContent {
        let packageBase = parsedEPUB.packageBaseDirectory
        let chapterURL = packageBase.appendingPathComponent(href)
        let text = try String(contentsOf: chapterURL, encoding: .utf8)
        return ChapterContent(
            body: XHTMLBodyExtractor.extractBody(from: text),
            baseURL: chapterURL.deletingLastPathComponent()
        )
    }
}

private enum XHTMLBodyExtractor {
    static func extractBody(from text: String) -> String {
        guard let openRange = text.range(of: "<body", options: [.caseInsensitive]),
              let openEnd = text[openRange.upperBound...].firstIndex(of: ">") else {
            return text
        }

        guard let closeRange = text.range(of: "</body>", options: [.caseInsensitive]) else {
            return String(text[text.index(after: openEnd)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return String(text[text.index(after: openEnd)..<closeRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
