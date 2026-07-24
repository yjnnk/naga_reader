import Foundation

public enum ReadingTheme: String, Codable, CaseIterable {
    case light
    case dark
    case sepia
}

public enum ReadingMode: String, Codable, CaseIterable {
    case paged
    case scroll
}

public struct ReadingSettings: Equatable, Codable {
    public let columnWidth: Int
    public let pageMargin: Int
    public let fontSize: Int
    public let lineHeight: Double
    public let theme: ReadingTheme
    public let readingMode: ReadingMode

    public static let `default` = ReadingSettings(
        columnWidth: 680,
        pageMargin: 72,
        fontSize: 19,
        lineHeight: 1.55,
        theme: .sepia,
        readingMode: .paged
    )

    public init(
        columnWidth: Int,
        pageMargin: Int,
        fontSize: Int,
        lineHeight: Double,
        theme: ReadingTheme,
        readingMode: ReadingMode = .paged
    ) {
        self.columnWidth = columnWidth
        self.pageMargin = pageMargin
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.theme = theme
        self.readingMode = readingMode
    }

    public func with(
        columnWidth: Int? = nil,
        pageMargin: Int? = nil,
        fontSize: Int? = nil,
        lineHeight: Double? = nil,
        theme: ReadingTheme? = nil,
        readingMode: ReadingMode? = nil
    ) -> ReadingSettings {
        ReadingSettings(
            columnWidth: columnWidth ?? self.columnWidth,
            pageMargin: pageMargin ?? self.pageMargin,
            fontSize: fontSize ?? self.fontSize,
            lineHeight: lineHeight ?? self.lineHeight,
            theme: theme ?? self.theme,
            readingMode: readingMode ?? self.readingMode
        )
    }

    private enum CodingKeys: String, CodingKey {
        case columnWidth
        case pageMargin
        case fontSize
        case lineHeight
        case theme
        case readingMode
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        columnWidth = try container.decode(Int.self, forKey: .columnWidth)
        pageMargin = try container.decode(Int.self, forKey: .pageMargin)
        fontSize = try container.decode(Int.self, forKey: .fontSize)
        lineHeight = try container.decode(Double.self, forKey: .lineHeight)
        theme = try container.decode(ReadingTheme.self, forKey: .theme)
        readingMode = try container.decodeIfPresent(ReadingMode.self, forKey: .readingMode) ?? .paged
    }
}
