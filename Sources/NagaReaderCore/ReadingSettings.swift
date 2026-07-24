import Foundation

public enum ReadingTheme: String, Codable, CaseIterable {
    case light
    case dark
    case sepia
}

public struct ReadingSettings: Equatable, Codable {
    public let columnWidth: Int
    public let pageMargin: Int
    public let fontSize: Int
    public let lineHeight: Double
    public let theme: ReadingTheme

    public static let `default` = ReadingSettings(
        columnWidth: 680,
        pageMargin: 72,
        fontSize: 19,
        lineHeight: 1.55,
        theme: .sepia
    )

    public init(
        columnWidth: Int,
        pageMargin: Int,
        fontSize: Int,
        lineHeight: Double,
        theme: ReadingTheme
    ) {
        self.columnWidth = columnWidth
        self.pageMargin = pageMargin
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.theme = theme
    }

    public func with(
        columnWidth: Int? = nil,
        pageMargin: Int? = nil,
        fontSize: Int? = nil,
        lineHeight: Double? = nil,
        theme: ReadingTheme? = nil
    ) -> ReadingSettings {
        ReadingSettings(
            columnWidth: columnWidth ?? self.columnWidth,
            pageMargin: pageMargin ?? self.pageMargin,
            fontSize: fontSize ?? self.fontSize,
            lineHeight: lineHeight ?? self.lineHeight,
            theme: theme ?? self.theme
        )
    }
}
