import Foundation

public struct BookID: Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}

public struct ImportedBookRecord: Equatable, Codable, Identifiable {
    public let id: BookID
    public let title: String
    public let originalFileName: String
    public let storedURL: URL

    public init(id: BookID, title: String, originalFileName: String, storedURL: URL) {
        self.id = id
        self.title = title
        self.originalFileName = originalFileName
        self.storedURL = storedURL
    }
}

public enum EPUBImportError: Error, Equatable, LocalizedError {
    case unsupportedFileType
    case couldNotCopyBook

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "Only EPUB files are supported."
        case .couldNotCopyBook:
            return "Could not copy the EPUB into app storage."
        }
    }
}
