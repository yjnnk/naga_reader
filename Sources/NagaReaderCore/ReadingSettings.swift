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

public enum ReadingFontFamily: String, Codable, CaseIterable, Identifiable {
    case system
    case newYork
    case georgia
    case athelas
    case palatino
    case charter
    case iowanOldStyle
    case menlo

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .system:
            return "System"
        case .newYork:
            return "New York"
        case .georgia:
            return "Georgia"
        case .athelas:
            return "Athelas"
        case .palatino:
            return "Palatino"
        case .charter:
            return "Charter"
        case .iowanOldStyle:
            return "Iowan Old Style"
        case .menlo:
            return "Menlo"
        }
    }

    public var cssFontStack: String {
        switch self {
        case .system:
            return "-apple-system, BlinkMacSystemFont, \"New York\", Georgia, serif"
        case .newYork:
            return "\"New York\", Georgia, serif"
        case .georgia:
            return "Georgia, \"Times New Roman\", serif"
        case .athelas:
            return "Athelas, Georgia, serif"
        case .palatino:
            return "\"Palatino\", \"Palatino Linotype\", Georgia, serif"
        case .charter:
            return "Charter, Georgia, serif"
        case .iowanOldStyle:
            return "\"Iowan Old Style\", Georgia, serif"
        case .menlo:
            return "Menlo, Monaco, Consolas, monospace"
        }
    }
}

public struct ReadingSettings: Equatable, Codable {
    public let columnWidth: Int
    public let pageMargin: Int
    public let fontSize: Int
    public let lineHeight: Double
    public let theme: ReadingTheme
    public let readingMode: ReadingMode
    public let fontFamily: ReadingFontFamily

    public static let `default` = ReadingSettings(
        columnWidth: 680,
        pageMargin: 72,
        fontSize: 19,
        lineHeight: 1.55,
        theme: .sepia,
        readingMode: .paged,
        fontFamily: .system
    )

    public init(
        columnWidth: Int,
        pageMargin: Int,
        fontSize: Int,
        lineHeight: Double,
        theme: ReadingTheme,
        readingMode: ReadingMode = .paged,
        fontFamily: ReadingFontFamily = .system
    ) {
        self.columnWidth = columnWidth
        self.pageMargin = pageMargin
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.theme = theme
        self.readingMode = readingMode
        self.fontFamily = fontFamily
    }

    public func with(
        columnWidth: Int? = nil,
        pageMargin: Int? = nil,
        fontSize: Int? = nil,
        lineHeight: Double? = nil,
        theme: ReadingTheme? = nil,
        readingMode: ReadingMode? = nil,
        fontFamily: ReadingFontFamily? = nil
    ) -> ReadingSettings {
        ReadingSettings(
            columnWidth: columnWidth ?? self.columnWidth,
            pageMargin: pageMargin ?? self.pageMargin,
            fontSize: fontSize ?? self.fontSize,
            lineHeight: lineHeight ?? self.lineHeight,
            theme: theme ?? self.theme,
            readingMode: readingMode ?? self.readingMode,
            fontFamily: fontFamily ?? self.fontFamily
        )
    }

    private enum CodingKeys: String, CodingKey {
        case columnWidth
        case pageMargin
        case fontSize
        case lineHeight
        case theme
        case readingMode
        case fontFamily
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        columnWidth = try container.decode(Int.self, forKey: .columnWidth)
        pageMargin = try container.decode(Int.self, forKey: .pageMargin)
        fontSize = try container.decode(Int.self, forKey: .fontSize)
        lineHeight = try container.decode(Double.self, forKey: .lineHeight)
        theme = try container.decode(ReadingTheme.self, forKey: .theme)
        readingMode = try container.decodeIfPresent(ReadingMode.self, forKey: .readingMode) ?? .paged
        fontFamily = try container.decodeIfPresent(ReadingFontFamily.self, forKey: .fontFamily) ?? .system
    }
}
